function [buf] = zeroCircularBuf(buf, ind, len) 
    % copyFromCircularBuf()
    % Returns a length of data from a circular buffer which starts at a
    % given index.
    %
    % Arguments:
    % buf:
    %       The buffer to copy data from.
    % ind:
    %       The index of the buffer at which to start copying data from.
    % len:
    %       The amount of data to copy.
    %
    % Returns:
    % data:
    %       The specified data from the buffer.
    
    if(len > length(buf))
        fprintf("ERROR: Tried to copy too much data from a circular buffer.\n");
        return;
    end
    
    
    % Because it's a circular buffer, split the copy into two sections:
    % - The first section of data, from the buffer index to the end of the
    %       data, or the end of the buffer, whichever comes first.
    % - If the data wraps to the beginning of the buffer, then copy a 2nd
    %       section of data starting at the beginning of the buffer.
    firstLen = len;
    if(ind + firstLen > length(buf))
        firstLen = length(buf) - ind + 1;
    end
    secondLen = len - firstLen;
    
    % Perform both copies.
    data(1:firstLen) = zeros(firstLen, 1);
    if(secondLen > 0)
        data(firstLen+1:firstLen+secondLen) = zeros(secondLen, 1);
    end
end