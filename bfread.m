function output = bfread(filename, varargin)
% bfread: load data using LOCI Bio-Formats importers
% 
% Usage: 
%           metadata = bfread(filename)
%           data = bfread(filename, series, ...)
%
% If called with only one argument, bfread works exactly the same way as
% bfinfo.  It opens the file using Bio-Formats and returns a simplified 
% metadata structure as a cell array containing one element for each series.  
%
% In normal usage, you would provide a series for bfread to open, as well as
% additional options in order to specify the 'Channel' and 'TimePoint' of
% interest.  These option are specified as key-value pairs.  
%
% A full usage example then may look like this:
%           >> data = bfread(filename, 2, 'TimePoint', 15, 'Channel', 1);
%			>> % now we can do something with "data"
%
% Additionally, it is possible to specify a region of interest using the
% 'CropRegion' option.  The associated parameter is a six element vector of
% indices populated as follows: [minx miny minz maxx maxy maxz].
%
% Multiple time points within a series may be read by specifying the
% 'TimePoints' keyword parameter (note the plural).  Its value can either  
% be an array of time indices or the string 'all' if you want to read them
% all.  When this option is active, the data is returned as a cell array of
% images/volumes.
%
% There is also an option to return the image data in its native precision.
% To do so just set the 'NativePrecision' option to true in the call.  By
% default the routine returns data casted to double.
%
% By default, a progress bar is shown.  To suppress the progress bar set
% the keyword option 'ShowProgress' to false.
%
% Currently this routine has been tested with XYZ, XYZT, XYZCT data contained 
% in Leica LIF files and Imaris 5.5 files.  Other scenarios may or may not work.
% 
% Pramukta Kumar
% Dept of Physics
% Georgetown University
%
    parser = inputParser;
    parser.addRequired('filename', @ischar);
    parser.addOptional('Series', 0, @(x)isnumeric(x) && x > 0);
    parser.addParamValue('CropRegion', false, ... 
        @(x)isnumeric(x) && isequal(numel(x), 6) && ...
        isequal(sum(x(1:3) > x(4:6)), 0) );
    parser.addParamValue('Channel', 1, @isnumeric);
    parser.addParamValue('TimePoint', 1, @isnumeric);
    parser.addParamValue('TimePoints', [], @(x) isnumeric(x) || isequal(x, 'all'));
    parser.addParamValue('ShowProgress', true, @islogical);
    parser.addParamValue('NativePrecision', false, @islogical); 
   
    parser.parse(filename, varargin{:});
    Parameters = parser.Results;
    
    % populate actual image data
    if(Parameters.Series > 0)
      [reader omemd] = bfinit(filename);
      % populate basic metadata
      numSeries = reader.getSeriesCount();
      
      index = Parameters.Series - 1; 
      % fetch the specified series
      reader.setSeries(index);
      width = reader.getSizeX();
      height = reader.getSizeY();
      depth = reader.getSizeZ();
      timepoints = reader.getSizeT();
       
      if(~Parameters.CropRegion)
        % set the CropRegion to be the full frame
        Parameters.CropRegion = [1 1 1 width height depth];
      end

      width = numel(Parameters.CropRegion(1):Parameters.CropRegion(4));
      height = numel(Parameters.CropRegion(2):Parameters.CropRegion(5));
      z_indices = Parameters.CropRegion(3):Parameters.CropRegion(6);
      depth = numel(z_indices);
      
      c_index = Parameters.Channel;
      
      if(isempty(Parameters.TimePoints))
          t_indices = Parameters.TimePoint;
      elseif(isequal(Parameters.TimePoints, 'all'))
          t_indices = 1:timepoints;
      else
          t_indices = Parameters.TimePoints;
      end
      
      if(Parameters.NativePrecision)
          pixelType = reader.getPixelType;
      else
          pixelType = loci.formats.FormatTools.DOUBLE;
      end
      
      switch pixelType
          case loci.formats.FormatTools.UINT8
              castfn = @uint8;
          case loci.formats.FormatTools.UINT16
              castfn = @uint16;
          case loci.formats.FormatTools.UINT32
              castfn = @uint32;
          case loci.formats.FormatTools.INT8
              castfn = @int8;
          case loci.formats.FormatTools.INT16
              castfn = @int16;
          case loci.formats.FormatTools.INT32
              castfn = @int32;
          case loci.formats.FormatTools.DOUBLE
              castfn = @double;
          case loci.formats.FormatTools.FLOAT
              castfn = @single;
          otherwise
              castfn = @double;
      end
      
      output = cell(numel(t_indices), 1);
      tmp = zeros(width, height, depth, char(castfn));
      if(Parameters.ShowProgress)
          hProgress = waitbar(0, sprintf('Loading Slices (%u/%u)', 0, depth*numel(t_indices)), ...
                          'WindowStyle', 'modal');
      end
      tic;
      for t = 1:numel(t_indices)
          for i = 1:depth
            if(Parameters.ShowProgress && toc > 0.1)
                waitbar(i*t / (depth*numel(t_indices)), hProgress, sprintf('Loading Slices (%u/%u)', i*t, depth*numel(t_indices)));
                tic;
            end
            % params 2 and 3 are for channel and time coordinates
            index = reader.getIndex(z_indices(i) - 1, c_index - 1, t_indices(t) - 1);
            raw_data = reader.openImage(index);
            slice_data = raw_data.getData.getPixels(Parameters.CropRegion(1) - 1, ...
                                                    Parameters.CropRegion(2) - 1, ...
                                                    width, height, []);
            tmp(:,:,i) = castfn(reshape(slice_data, [width height]));
          end
          output{t} = tmp;
      end
      if(Parameters.ShowProgress)
          delete(hProgress);
      end
      reader.close;
      if(isequal(numel(output), 1))
          output = output{1};
      end
    else
      output = bfinfo(filename);
    end
end
