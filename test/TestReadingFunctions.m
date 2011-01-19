classdef TestReadingFunctions < TestCase
    properties
		dataPath
    end
    methods
        function self = TestReadingFunctions(name)
            self = self@TestCase(name);
        end
        
		function setUp(self)
			me = which('TestReadingFunctions');
	        [p f e v] = fileparts(me);
			self.dataPath = fullfile(p, 'data');
		end
		
		function tearDown(self)
		end

		function testLIFReadMetadata(self)
            metadata = bfinfo(fullfile(self.dataPath, 'xyzc.lif'));
            assertEqual(6, numel(metadata), 'unexpected number of metadata elements');
            assertElementsAlmostEqual([0.2827 0.2827 0.0420], metadata{2}.pixelDimensions, ...
                'absolute', 0.0001, ...
                'unexpected pixel size');
            assertEqual([512 512 1], metadata{1}.imageDimensions, ...
                'unexpected image dimensions');
            
            % verify that bfread with one argument and bfinfo return
            % identical results
            md1 = bfinfo(fullfile(self.dataPath, 'xyzc.lif'));
            md2 = bfread(fullfile(self.dataPath, 'xyzc.lif'));
            
            assertEqual(md1, md2, 'bfread with one argument, bfinfo return different results');
		end

		function testIMSReadMetadata(self)
		end
		
		function testLIFReadData(self)
            channel1 = bfread(fullfile(self.dataPath, 'xyzc.lif'), 1, 'Channel', 1);
            channel2 = bfread(fullfile(self.dataPath, 'xyzc.lif'), 1, 'Channel', 2);
            
            assertEqual(1320763, sum(channel1(:)), 'channel data checksum failed')
            assertFalse(isequal(channel1, channel2), 'channels 1 and two should not be the same');
		end
		
		function testIMSReadData(self)			
		end

        function testTruth(self)
            assertTrue(true, 'What is true should be true');
        end
    end 
end