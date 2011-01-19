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
              
       if(~Parameters.CropRegion)
           % set the CropRegion to be the full frame
           Parameters.CropRegion = [1 1 1 width height depth];
       end
       
       width = numel(Parameters.CropRegion(1):Parameters.CropRegion(4));
       height = numel(Parameters.CropRegion(2):Parameters.CropRegion(5));
       z_indices = Parameters.CropRegion(3):Parameters.CropRegion(6);
       depth = numel(z_indices);
       
       c_index = Parameters.Channel;
       t_index = Parameters.TimePoint;
       
       output = zeros(width, height, depth);
       hProgress = waitbar(0, sprintf('Loading Slices (%u/%u)', 0, depth), ...
           'WindowStyle', 'modal');
       for i = 1:depth
           waitbar(i / depth, hProgress, sprintf('Loading Slices (%u/%u)', i, depth));
           % params 2 and 3 are for channel and time coordinates
           index = reader.getIndex(z_indices(i) - 1, c_index - 1, t_index - 1);
           raw_data = reader.openImage(index);
           slice_data = raw_data.getData.getPixels(Parameters.CropRegion(1) - 1, ...
               Parameters.CropRegion(2) - 1, ...
               width, height, []);
           output(:,:,i) = reshape(slice_data, [width height]);
       end
       delete(hProgress);
       reader.close;
    else
 	   output = bfinfo(filename);
   	end
end
