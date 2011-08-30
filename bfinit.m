function [reader omemd] = bfinit(filename)
% bfinit: Initialize the Bio-Formats library to read a file
%
% This routine is not intended for general use.  It is only used to
% encapsulate some of the repetitive steps involved in preparing to use the
% Bio-Formats library as a reader.
%
% If you do use this routine, make sure to close the reader once you are done.

    loci_tools_jar = 'loci_tools-4.2.2.jar';
    
    % read the java classpath
    javapaths = javaclasspath;
    for i = 1:numel(javapaths)
        [p f e] = fileparts(javapaths{i});
        javapaths{i} = strcat(f, '.', e);
    end
    if(isequal(strmatch(loci_tools_jar, javapaths), []))
        % find the absolute path of the jar file
        me = which('bfread');
        [p f e] = fileparts(me);
        % trunk version
        javaaddpath(fullfile(p, 'ext', loci_tools_jar));
        % release version
        % javaaddpath(fullfile(p, loci_tools_jar));        
    end

    % quick and dirty log4j initialization
    org.apache.log4j.BasicConfigurator.configure;
    org.apache.log4j.Logger.getRootLogger.setLevel(org.apache.log4j.Level.INFO);
    
    % construct a reader
    reader = loci.formats.ImageReader;
    % wrap it in a BufferedImageReader
    reader = loci.formats.gui.BufferedImageReader(reader);
    % construct Metadata container
    omemd = loci.formats.ome.OMEXMLMetadataImpl;
    % omemd = loci.formats.MetadataTools.createOMEXMLMetadata();
    reader.setMetadataStore(omemd);
    reader.setMetadataFiltered(false);
    % make sure the reader actually collects the metadata
    reader.setMetadataCollected(true);
    reader.setOriginalMetadataPopulated(true);

    if(ispc)
        if(regexp(filename,'^\w\:\\', 'once')) % windows absolute path
            reader.setId(filename);
        else
            reader.setId(fullfile(pwd, filename));
        end
    else
        if(filename(1) == '/') % unix absolute path
            reader.setId(filename);
        else
            reader.setId(fullfile(pwd, filename));
        end
    end
end