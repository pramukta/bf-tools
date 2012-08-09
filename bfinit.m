function [reader omemd] = bfinit(filename)
% bfinit: Initialize the Bio-Formats library to read a file
%
% This routine is not intended for general use.  It is only used to
% encapsulate some of the repetitive steps involved in preparing to use the
% Bio-Formats library as a reader.
%
% If you do use this routine, make sure to close the reader once you are done.

	% I hope this doesn't change
    loci_tools_remote_path = 'http://loci.wisc.edu/files/software/loci_tools.jar';
	loci_tools_jar = 'loci_tools.jar';
    
    % read the java classpath
    javapaths = javaclasspath;
    for i = 1:numel(javapaths)
        [p f e] = fileparts(javapaths{i});
        javapaths{i} = strcat(f, '.', e);
    end
    if(isequal(strmatch(loci_tools_jar, javapaths), []))
        % find our absolute path of the jar file
        me = which('bfinit');
        [p f e] = fileparts(me);
		% check if loci_tools_jar has been downloaded already
		loci_tools_local_path = fullfile(p, 'ext', loci_tools_jar);
		% if not then download it to that location
		if(isequal(exist(loci_tools_local_path, 'file'), 0))
			fprintf('BioFormats library not found at location: %s\n', loci_tools_local_path);
            fprintf('  Downloading current version from: %s\n', loci_tools_remote_path);
            urlwrite(loci_tools_remote_path, loci_tools_local_path, 'get', {});
            fprintf('Completed.\n\n');
		end
		% and add that location to our java path
        javaaddpath(loci_tools_local_path);
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