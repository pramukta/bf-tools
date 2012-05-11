function [output] = bfstream(filename, series, block, varargin)
    parser = inputParser;
    parser.addRequired('filename', @ischar);
    parser.addRequired('series', @(x) isnumeric(x) && x > 0);
    parser.addParamValue('IgnoreOutput', true, @islogical);
    parser.addParamValue('ShowProgress', false, @islogical);
    parser.addParamValue('NativePrecision', false, @islogical); 
    
    parser.parse(filename, series, varargin{:});
    Parameters = parser.Results;
    
    [reader omemd] = bfinit(filename);
    
    % populate basic metadata
    numSeries = reader.getSeriesCount();
    index = series - 1; 
    % fetch the specified series
    reader.setSeries(index);
    
    % read series geometry
    width = reader.getSizeX();
    height = reader.getSizeY();
    N = reader.getImageCount;
    
    % prepare output structure
    if(Parameters.IgnoreOutput)
        output = false;
    else
        output = cell(1,N);
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
    
    % work begins
    if(Parameters.ShowProgress)
        hProgress = waitbar(0, sprintf('Processing Slices (%u/%u)', 0, N), ...
                            'WindowStyle', 'modal');
    end
    tic;        
    for index = 1:N
        if(Parameters.ShowProgress && toc > 0.1)
            waitbar(index / N, hProgress, sprintf('Processing Slices (%u/%u)', index, N));
            tic;
        end
        % params 2 and 3 are for channel and time coordinates
        zct = reader.getZCTCoords(index);        
        raw_data = reader.openImage(index);
        
        slice_data = raw_data.getData.getPixels(0, 0, width, height, []);
        slice_data = castfn(reshape(slice_data, [width height]));
        
        if(Parameters.IgnoreOutput)
            block(slice_data, transpose(zct));
        else
            output{index} = block(slice_data, transpose(zct));
        end
    end
    
    if(Parameters.ShowProgress)
        delete(hProgress);
    end
    reader.close;
end
