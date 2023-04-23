clear;
close all;


[audio, fs] = audioread("test.wav");

% frameLen = 500;
% audio = 1:24000;
% fs = 12000;

deviceWriter = audioDeviceWriter('SampleRate', fs, 'SupportVariableSizeInput', true);
frameLen = 5000;



bufMin = round(fs/4);
bufMax = 2*fs;
% bufMin = 50;
% bufMax = 7000;

readBuf = zeros(bufMax, 1);
writeBuf = zeros(bufMax*3, 1);

readBufInd = 1;
writeBufReadInd = 1;
writeBufWriteInd = -1;

mix = parameterRef;
mix.name = "Mix";
mix.value = 0.3;

bufSize = parameterRef;
bufSize.name = "Frame Length";
bufSize.value = bufMax/2;

parametersTuningUI([bufSize, mix], [[bufMin, bufMax]; [0, 1]]);

fullOut = 0;
writeAmount = 0;
boundaries = [0];

onsets = [];

last_detected_onset = 0;
x2_prev = 0;

last_onset = 0;

frameStart = 1;
while(frameStart < length(audio))
    % Determine frame boundaries
    frameEnd = frameStart + frameLen - 1;
    if(frameEnd > length(audio))
        frameEnd = length(audio);
    end
    currFrameLen = frameEnd - frameStart + 1;
    
    frame = audio(frameStart:frameEnd);
    
    
    % Detect onsets
    for i=1:length(frame)
        x = frame(i);
        x2 = x^2;
        
        deriv = x2 - x2_prev;
        loc = frameStart+i;
        
        if(deriv > 0.1 && loc-last_detected_onset > 600)
            onsets = [onsets, loc];
            last_detected_onset = loc;
        end
        
        x2_prev = x2;
    end

    
    
      
    % Update buffer size from UI
    drawnow limitrate
    bufSize.value = round(bufSize.value);
%     if(frameStart <= 12000 && frameEnd >= 12000)
%         fprintf("CHANGING BUF SIZE\n");
%         bufSize.value = bufMax-800;
%     end
    

    % If changing the buffer size made it smaller than the 
    if(readBufInd >= bufSize.value)
        fprintf("EARLY FLUSH\n");
        data = copyFromCircularBuf(readBuf, 1, bufSize.value);
%         data = flip(data);
        if(debug)
            fprintf("Flushing...\n");
%             fprintf("Data\n");
%             printArray(data, -1);
        end
        if(writeBufWriteInd == -1)
            writeBufWriteInd = writeBufReadInd+rCopyLen;
            if(writeBufWriteInd > length(writeBuf))
                writeBufWriteInd = writeBufWriteInd - length(writeBuf);
            end
        end
        
        writeBuf = copyToCircularBuf(writeBuf, writeBufWriteInd, data);
        writeBufWriteInd = writeBufWriteInd + length(data);
        if(writeBufWriteInd > length(writeBuf))
            writeBufWriteInd = writeBufWriteInd - length(writeBuf);
            if(writeBufWriteInd > writeBufReadInd)
                fprintf("ERROR: DATA OVERLAP\n");
                return;
            end
        end
        
        writeAmount = writeAmount + length(data);
        boundaries = [boundaries, writeAmount];
        if(debug)
            fprintf("Writing %d into writeBuf\n", length(data));
            
            if(writeBufWriteInd < writeBufReadInd)
                fprintf("writebuf fill: %d\n", length(writeBuf) - (writeBufReadInd - writeBufWriteInd));
            else
                fprintf("writebuf fill: %d\n", writeBufWriteInd - writeBufReadInd);
            end
        end
%         fullOut = [fullOut; data];
        readBuf = zeros(bufMax, 1);
        readBufInd = 1;
        
        if(debug)
            
%             fprintf("WriteBuf Read Index: %d\n", writeBufReadInd);
%             printArray(writeBuf, writeBufReadInd);
        end
        
    end
    
    
    
    
    
    
    
    if(frameEnd > 0 && frameStart < 4000150)
        debug = false;
    else
        debug = false;
    end
    
    if(debug)
        fprintf("\n\nFRAME RECEIVED\n");
        fprintf("Frame len: %d\n", length(frame));
    end
    
    rCopyLen = currFrameLen;
    if(readBufInd + currFrameLen > bufSize.value)
        rCopyLen = bufSize.value - readBufInd + 1;
    end
    rCopyLeftover = currFrameLen - rCopyLen;
    
    if(debug)
        fprintf("CopyLen: %d\n", rCopyLen);
        fprintf("Leftover: %d\n", rCopyLeftover);
        fprintf("Read buf fill: %d\n", readBufInd-1);
    end
    
    readBuf = copyToCircularBuf(readBuf, readBufInd, frame(1:rCopyLen));
    readBufInd = readBufInd + rCopyLen;
    if(debug)
        fprintf("Copying %d to readBuf\n", rCopyLen);
        fprintf("Read buf fill: %d\n", readBufInd-1);
%         fprintf("Copy to Circular Buf: %d:%d\n", 1, rCopyLen);
%         fprintf("ReadBuf Index: %d\n", readBufInd);
%         printArray(readBuf, readBufInd);
    end
    
    if(readBufInd >= bufSize.value)
        data = copyFromCircularBuf(readBuf, 1, bufSize.value);
        data = flip(data);
        if(debug)
            fprintf("Flushing...\n");
%             fprintf("Data\n");
%             printArray(data, -1);
        end
        if(writeBufWriteInd == -1)
            writeBufWriteInd = writeBufReadInd+rCopyLen;
            if(writeBufWriteInd > length(writeBuf))
                writeBufWriteInd = writeBufWriteInd - length(writeBuf);
            end
        end
        
        if(writeBufWriteInd < writeBufReadInd)
            writefill = length(writeBuf) - (writeBufReadInd - writeBufWriteInd);
        else
            writefill = writeBufWriteInd - writeBufReadInd;
        end
        
        if(length(writeBuf) - writefill < length(data)) 
            fprintf("OVERLAP DETECTED\n");
            fprintf("fill: %d\n", writefill);
            fprintf("space: %d\n", length(writeBuf) - writefill);
            fprintf("data len: %d\n", length(data));
            return;
        end
        
        writeBuf = copyToCircularBuf(writeBuf, writeBufWriteInd, data);
        writeBufWriteInd = writeBufWriteInd + length(data);
        if(writeBufWriteInd > length(writeBuf))
            writeBufWriteInd = writeBufWriteInd - length(writeBuf);
            if(writeBufWriteInd > writeBufReadInd)
                fprintf("ERROR: DATA OVERLAP\n");
                return;
            end
        end
        
        writeAmount = writeAmount + length(data);
        boundaries = [boundaries, writeAmount];
        if(debug)
            fprintf("Writing %d into writeBuf\n", length(data));
            
            if(writeBufWriteInd < writeBufReadInd)
                fprintf("writebuf fill: %d\n", length(writeBuf) - (writeBufReadInd - writeBufWriteInd));
            else
                fprintf("writebuf fill: %d\n", writeBufWriteInd - writeBufReadInd);
            end
        end
%         fullOut = [fullOut; data];
        readBuf = zeros(bufMax, 1);
        readBufInd = 1;
        
        if(debug)
            
%             fprintf("WriteBuf Read Index: %d\n", writeBufReadInd);
%             printArray(writeBuf, writeBufReadInd);
        end
        
    end
    
    if(rCopyLeftover > 0)
        readBuf = copyToCircularBuf(readBuf, readBufInd, frame(rCopyLen+1:currFrameLen));
        readBufInd = readBufInd + rCopyLeftover;
        if(readBufInd > bufSize.value)
            readBufInd = readBufInd - bufSize.value;
        end
        if(debug)
            fprintf("Copying %d to readBuf\n", rCopyLeftover);
            fprintf("Readbuf fill: %d\n", readBufInd-1);
%             fprintf("Copy to Circular Buf: %d:%d\n", rCopyLen+1, rCopyLen+rCopyLeftover);
%             fprintf("ReadBuf Index: %d\n", readBufInd);
%             printArray(readBuf, readBufInd)
        end
    end

        
%     
%     copyLen = bufSize - writeBufInd;
%     if(copyLen > frameLen)
%         copyLen = frameLen;
%     end
%     
%     buf(bufWriteInd:bufWriteInd+copyLen) = frame(frameStart:frameStart+copyLen);
%     bufWriteInd = bufWriteInd + copyLen;
%     
%     if(bufWriteInd >= bufMax)
%         
%     end
%     
%     leftOver = frameLen - copyLen;
%         

    output = copyFromCircularBuf(writeBuf, writeBufReadInd, frameLen);
    fullOut = [fullOut; output];
    writeBufReadInd = writeBufReadInd + frameLen;
    if(writeBufReadInd > length(writeBuf))
        writeBufReadInd = writeBufReadInd - length(writeBuf);
        if(writeBufReadInd > writeBufWriteInd)
            fprintf("ERROR RAN OUT OF BUF1\n");
%             return;
        end
        writeBufWriteInd = -1;
    else
        if(writeBufReadInd > writeBufWriteInd)
            if(debug)
                fprintf("ERROR RAN OUT OF BUF\n");
            end
            writeBufWriteInd = -1;
%             return;
        end
    end
    if(debug)
        fprintf("Reading %d from writebuf\n", frameLen);
        if(writeBufWriteInd < writeBufReadInd)
            fprintf("writebuf fill: %d\n", length(writeBuf) - (writeBufReadInd - writeBufWriteInd));
        else
            fprintf("writebuf fill: %d\n", writeBufWriteInd - writeBufReadInd);
        end
            
    end

    reversed = output;
    
%     output = mix.value*frame + (1-mix.value)*reversed;
    
%     deviceWriter(reversed);
    

    frameStart = frameStart + frameLen;
end

figure;
subplot(211);
hold on;
plot(audio);
for i=onsets
    scatter(i, audio(i));
end

subplot(212);
plot(fullOut);
hold on;
for b=boundaries
    xline(b);
end



release(deviceWriter);

function [] = printArray(arr, ind)
    i = 1;
    while i <= length(arr)
        if(i == ind)
            fprintf("IND: ");
        end
        fprintf("%d", arr(i));
        if(mod(i, 20) == 0)
            fprintf("\n");
        else
            fprintf(", ");
        end
        i = i + 1;
    end
    fprintf("\n\n");
end


function data = copyFromCircularBuf(buf, ind, len) 
    data = zeros(len, 1);
    
    firstLen = len;
    if(ind + firstLen > length(buf))
        firstLen = length(buf) - ind + 1;
    end
    secondLen = len - firstLen;
    
    data(1:firstLen) = buf(ind:ind+firstLen-1);
    data(firstLen+1:end) = buf(1:secondLen);
end

function outbuf = copyToCircularBuf(inbuf, ind, data)
%     fprintf("Length of data: %d\n", length(data));
%     fprintf("Length of buf: %d\n", length(inbuf));
    copylen = length(data);
    if(ind + copylen > length(inbuf))
        copylen = length(inbuf) - ind + 1;
    end
    
    outbuf = inbuf;
    
    leftoverlen = length(data) - copylen;
    
%     fprintf("copylen: %d\n", copylen);
%     fprintf("leftoverlen: %d\n", leftoverlen);
    
%     fprintf("%d : %d = %d : %d\n", ind, ind+copylen-1, 1, copylen);
    outbuf(ind:ind+copylen-1) = data(1:copylen);
%     fprintf("%d : %d = %d : %d\n", 1, leftoverlen, copylen+1, copylen+leftoverlen);
    if(leftoverlen > 0)
        outbuf(1:leftoverlen) = data(copylen+1:copylen+leftoverlen);
    end
end










% rdApp()
% 
% function rdApp
%     fig = uifigure;
%     fig.Name = "Reverse Delay";
%     
%     gl = uigridlayout(fig, [2, 1]);
%     gl.RowHeight = {30, '1x'};
%     gl.ColumnWidth = {'fit', '1x'};
%     
%     title = uilabel(gl);
%     title.Text = "Settings";
%     title.Layout.Row = 1;
%     title.Layout.Column = 1;
%     
%     len = uiaxes(gl);
%     len.Layout.Row = 2;
%     len.Layout.Column = 1;
% end
