function [buf] = copyToCircularBuf(buf, ind, data)
    % copyToCircularBuf()
    % Writes a given amount of data into a circular buffer, starting at a
    % given index.
    %
    % Arguments:
    % buf:
    %       The buffer to copy data into.
    % ind:
    %       The index of the buffer at which to start writing data.
    % data:
    %       The data to copy.
    
    if(length(data) > length(buf))
        fprintf("ERROR: Tried to write too much data into a circular buffer.\n");
        return;
    end
    
    
    
    % Because it's a circular buffer, split the copy into two sections:
    % - The first section of data, from the buffer index to the end of the
    %       data, or the end of the buffer, whichever comes first.
    % - If the data wraps to the beginning of the buffer, then copy a 2nd
    %       section of data starting at the beginning of the buffer.
    copylen = length(data);
    if(ind + copylen > length(buf))
        copylen = length(buf) - ind + 1;
    end    
    leftoverlen = length(data) - copylen;
    

    % Perform both copies.
    buf(ind:ind+copylen-1) = data(1:copylen);
    if(leftoverlen > 0)
        buf(1:leftoverlen) = data(copylen+1:copylen+leftoverlen);
    end
end
