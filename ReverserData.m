classdef ReverserData < handle
    % Holds buffers, data, & settings for the reverser algorithm
    
    properties
        % There are two buffers in the reverser process. The program
        % collects samples from one note at a time, and stores them in a
        % read buffer. Once the entirety of the note has been collected,
        % the read buffer data is put into the write buffer, and collection
        % of the next note begins. The program continually reads from the 
        % write buffer to output samples to the user.
        readBuf;
        writeBuf;

        % The size of the read buffer array, which is the maximum length
        % that one note can be.
        bufMax;
                
        % The read buffer is not circular: note data is written into it
        % starting from the beginning. When a note is flushed into the
        % write buffer, the data starts again from the beginning of the
        % buffer. This index keeps track of the first unused sample in the
        % array - i.e. the sample which new data should be written into.
        readBufInd;
        
        % The write buffer is circular. There are two indices here. The
        % write index is the first unused position in the array: where to
        % write new data. The read index is the first sample of data in the
        % array: where to start reading data from. Unless the buffer runs
        % out of data, usable data in the array should be after the read
        % index and before the write index (remember that the buffer is
        % circular, so the write index could be before the read index - in
        % which case the data wraps around the end of the array).
        writeBufReadInd;
        writeBufWriteInd;

        % The sample rate of the input audio
        fs;
        
        
        % A boolean, whether or not the write buffer has data in it. If
        % not, then the program will output silence.
        writeBufEmpty;
        % If the write buffer is empty, this will contain the number of
        % consecutive samples of silence that have been outputted since the
        % buffer became empty. This is used to properly place the note
        % boundaries on the graph.
        emptyLen;
        
        
        % Whether or not to display debug messages
        debug;

    end
    methods
        function obj = ReverserData(Fs)
            % Constructor, initializes variables
            %
            % Arguments:
            % Fs:
            %       The sample rate of the input audio
            
            
            obj.fs = Fs;
            
            obj.readBufInd = 1;
            obj.writeBufReadInd = 1;
            obj.writeBufWriteInd = -1;
            
            obj.bufMax = 2*obj.fs;
            
            obj.readBuf = zeros(obj.bufMax, 1);
            % Limit notes to 3 seconds long
            obj.writeBuf = zeros(obj.bufMax, 1);
            
            obj.writeBufEmpty = true;
            obj.emptyLen = 0;
            
            obj.debug = false;
        end
        
        
        function data = copyReadBuf(r)
            % copyReadBuf() returns a copy of the entire read buffer
            %
            % Returns:
            % data:
            %       A copy of the entire read buffer
            
            data = copyFromCircularBuf(r.readBuf, 1, r.readBufInd-1);
        end
        
        
        
        
        
        function data = popWriteBuf(r, len)
            % popWriteBuf() pops and returns a given length of data from
            % the beginning of the write buffer's data. It will update the
            % write buffer indices. The returned data is zeroed in the
            % write buffer. If there is not enough write buffer data, then
            % the extra samples will be 0s. 
            %
            % Arguments:
            % len:
            %       The length of write buffer data to return
            % 
            % Returns:
            % data:
            %       The write buffer data
            
            % If a length is not specified, pop all the write buffer data
            if(nargin == 1)
                if(r.writeBufWriteInd < r.writeBufReadInd)
                    len = length(r.writeBuf) - (r.writeBufReadInd - r.writeBufWriteInd);
                else
                    len = r.writeBufWriteInd - r.writeBufReadInd;
                end
            end
            
            
            % Retrieve the data & zero it, so that when the write buffer is
            % empty, old data won't be output.
            data = copyFromCircularBuf(r.writeBuf, r.writeBufReadInd, len);
            r.writeBuf = zeroCircularBuf(r.writeBuf, r.writeBufReadInd, len);

            
            % Update write buffer indices 
            
            % If the write buffer was already empty, then update the
            % emptyLen and be done
            if(r.writeBufEmpty)
                r.emptyLen = r.emptyLen + len;
                
            % Otherwise, we have to check if the write buffer is newly
            % empty
            else
                % writeWrap: if true, the write buffer write index has
                % wrapped around to the beginning of the array and is
                % before the read index. This is before the read index
                % is updated
                if(r.writeBufReadInd > r.writeBufWriteInd)
                    writeWrap = true;
                else
                    writeWrap = false;
                end


                if(r.debug)
                    fprintf("WriteBuf WriteInd: %d\n", r.writeBufWriteInd);
                    fprintf("WriteBuf ReadInd: %d\n", r.writeBufReadInd);
                end

                % We've taken data from the write buffer, so update the
                % read index
                r.writeBufReadInd = r.writeBufReadInd + len;
                
                % Whether the buffer has become empty after the data was
                % removed from it
                bufNowEmpty = false;
                
                if(r.writeBufReadInd > length(r.writeBuf))
                    % If the read buffer has passed the end of the array,
                    % then make it wrap around to the beginning
                    r.writeBufReadInd = r.writeBufReadInd - length(r.writeBuf);

                    
                    % If the write index has passed the read index
                    if(writeWrap && r.writeBufReadInd > r.writeBufWriteInd)
                        bufNowEmpty = true;
                        
                    % If the write index has passed the read index
                    elseif(~writeWrap)
                        bufNowEmpty = true;
                    end
                else
                    % If the write index has passed the read index
                    if(writeWrap && r.writeBufWriteInd > r.writeBufReadInd)
                        bufNowEmpty = true;
                        
                    % If the write index has passed the read index
                    elseif(~writeWrap && r.writeBufReadInd > r.writeBufWriteInd)
                        bufNowEmpty = true;
                    end
                end
                
                % If the buffer has just become empty
                if(bufNowEmpty)
                    if(r.debug)
                        fprintf("RAN OUT OF BUF\n");
                    end
                    r.writeBufEmpty = true;

                    % Figure out how much of the data was from when the
                    % buffer was already empty, and update the emptyLen
                    empt = r.writeBufReadInd - r.writeBufWriteInd;
                    r.emptyLen = r.emptyLen + empt;
                end
            end
            
            if(r.debug)
                fprintf("WriteBuf WriteInd: %d\n", r.writeBufWriteInd);
                fprintf("WriteBuf ReadInd: %d\n", r.writeBufReadInd);

                fprintf("Reading %d from writebuf\n", len);
                if(r.writeBufWriteInd < r.writeBufReadInd)
                    fprintf("writebuf fill: %d\n", length(r.writeBuf) - (r.writeBufReadInd - r.writeBufWriteInd));
                else
                    fprintf("writebuf fill: %d\n", r.writeBufWriteInd - r.writeBufReadInd);
                end

            end
        end
        
        
        
        
        function [] = writeToWriteBuf(r, data)
            % writeToWriteBuf() writes the given data into the next
            % available space in the write buffer. 
            %
            % Arguments:
            % data:
            %       The data to put into the write buffer
            
            % Copy the data over
            r.writeBuf = copyToCircularBuf(r.writeBuf, r.writeBufWriteInd, data);
            
            % Move the write index now that there's new data in the buffer
            r.writeBufWriteInd = r.writeBufWriteInd + length(data);
            if(r.writeBufWriteInd > length(r.writeBuf))
                r.writeBufWriteInd = r.writeBufWriteInd - length(r.writeBuf);
                
                % If there is too much data to fit in the buffer, then
                % quit, because something has gone wrong
                if(r.writeBufWriteInd > r.writeBufReadInd)
                    fprintf("ERROR: DATA OVERLAP\n");
                    return;
                end
            end
            
            if(r.debug)
                fprintf("WriteBuf WriteInd: %d\n", r.writeBufWriteInd);
                fprintf("WriteBuf ReadInd: %d\n", r.writeBufReadInd);
            end
        
        end
        
        
        
        
        
        function [] = writeToReadBuf(r, data)
            % writeToReadBuf() writes the given data into the next
            % available space in the read buffer. 
            %
            % Arguments:
            % data:
            %       The data to put into the read buffer
            
            
            % Copye the data over
            r.readBuf = copyToCircularBuf(r.readBuf, r.readBufInd, data);
            
            % Update the buffer index
            r.readBufInd = r.readBufInd + length(data);
            
            if(r.debug)
                fprintf("Readbufind: %d\n", r.readBufInd);
                fprintf("\n");
            end

        end
        
        
        
        function [len] = flushReadBuf(r)
            % flushReadBuf() takes the contents of the read buffer and puts
            % it into the write buffer.
            %
            % Returns:
            % len:
            %       The amount of data that was flushed
            
            
            if(r.debug)
                fprintf("\nFlushing %d..\n", r.readBufInd);
            end

            % Get the data from the read buffer
            data = copyReadBuf(r);
            
            % Reset the read buffer index to the beginning
            r.readBufInd = 1;

            
            % Reverse it! This is the whole effect here
            data = flip(data);


            len = length(data);

            
            % writefill: How much data is contained in the write buffer
            if(r.writeBufWriteInd < r.writeBufReadInd)
                writefill = length(r.writeBuf) - (r.writeBufReadInd - r.writeBufWriteInd);
            else
                writefill = r.writeBufWriteInd - r.writeBufReadInd;
            end

            % If the data doesn't fit into the write buffer, quit, because
            % something has gone wrong.
            if(length(r.writeBuf) - writefill < length(data)) 
                fprintf("OVERLAP DETECTED\n");
                fprintf("fill: %d\n", writefill);
                fprintf("space: %d\n", length(r.writeBuf) - writefill);
                fprintf("data len: %d\n", length(data));
                return;
            end

            if(r.debug)
                fprintf("Writing %d into writeBuf\n", length(data));
                fprintf("WriteBuf WriteInd: %d\n", r.writeBufWriteInd);
                fprintf("WriteBuf ReadInd: %d\n", r.writeBufReadInd);
            end


            % Copy the data over to the write buffer
            r.writeToWriteBuf(data);


            if(r.debug)
                if(r.writeBufWriteInd < r.writeBufReadInd)
                    fprintf("writebuf fill: %d\n\n", length(r.writeBuf) - (r.writeBufReadInd - r.writeBufWriteInd));
                else
                    fprintf("writebuf fill: %d\n\n", r.writeBufWriteInd - r.writeBufReadInd);
                end
            end
        end
    end
end