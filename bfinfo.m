function [output] = bfinfo(filename, varargin)
% bfinfo: Read Metadata using LOCI Bio-Formats importers
%
% Usage: 
%           metadata = bfinfo(filename)
%
% This routine reads in basic metadata contained within microscopy datasets
% that are supported by the LOCI Bio-Formats library.  The metadata is
% returned as a cell array of structs that contain fields for the basic
% image properties.

    parser = inputParser;
    parser.addRequired('filename', @ischar);
    parser.parse(filename, varargin{:});
    Parameters = parser.Results;

    [reader omemd] = bfinit(filename);
    % populate a simple metadata structure
    numSeries = reader.getSeriesCount();
    output = cell(numSeries, 1);
    for i = 1:numSeries
       output{i} = struct();
       output{i}.name = char(omemd.getImageName(i-1));
       output{i}.description = char(omemd.getImageDescription(i-1));
       output{i}.format = char(reader.getFormat);
       % output{i}.date = char(omemd.getImageAcquisitionDate(i-1));
       try
           output{i}.pixelDimensions = ...
               double([omemd.getPixelsPhysicalSizeX(i-1).getValue, ...
                       omemd.getPixelsPhysicalSizeY(i-1).getValue, ...
                       omemd.getPixelsPhysicalSizeZ(i-1).getValue]);
           output{i}.pixelDimensions = reshape( ...
               output{i}.pixelDimensions, 1, ...
               numel(output{i}.pixelDimensions) );
       catch
           warning('BFINFO:WARN', 'There was an issue getting the physical pixel size.  It wont be available.');
       end

       output{i}.imageDimensions = [omemd.getPixelsSizeX(i-1).getValue, ...
                                    omemd.getPixelsSizeY(i-1).getValue, ...
                                    omemd.getPixelsSizeZ(i-1).getValue];
       output{i}.channels = omemd.getPixelsSizeC(i-1).getValue;
       output{i}.timePoints = omemd.getPixelsSizeT(i-1).getValue;
    end
    reader.close();
end