clear;
close all;
clc;


[audio, fs] = audioread("SampleAudio/riff3.wav");
% audio = 1:308701;
% fs = 44100;

deviceWriter = audioDeviceWriter('SampleRate', fs, 'SupportVariableSizeInput', true);
frameLen = 5000;

% Riff 1
threshold = 0.004;
minLen = 10000;

% Riff 3
% threshold = 0.009;
% minLen = 10000;

% Riff 4
% threshold = 0.004;
% minLen = 6000;



bufMin = round(fs/4);
bufMax = 2*fs;
% bufMin = 50;
% bufMax = 7000;

readBuf = zeros(bufMax, 1);
writeBuf = zeros(bufMax*3, 1);

readBufInd = 1;
writeBufReadInd = 1;
writeBufWriteInd = -1;

% mix = parameterRef;
% mix.name = "Mix";
% mix.value = 0.3;
% 
% bufSize = parameterRef;
% bufSize.name = "Frame Length";
% bufSize.value = bufMax/2;
% 
% parametersTuningUI([bufSize, mix], [[bufMin, bufMax]; [0, 1]]);

fullOut = 0;
writeAmount = 0;
boundaries = [0];
frameBounds = [0];


totWrite = 0;

overlap = false;


% preOnsets = [36664, 48596, 61632, 71707, 103483, 114944, 125220, 135919, 146904,...
%     169761, 205079, 215291, 225694, 235911, 248201, 293328, 303654];


onsetFrameLen = 128;
    
onsets = [];
allOnsets = [];

% allOnsets = preOnsets;

last_detected_onset = 0;
x2_prev = 0;

last_onset = 0;
energy_prev = 0;

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
        loc = frameStart+i-1;
        
        if((deriv > threshold && loc-last_detected_onset > minLen) || (loc-last_detected_onset >= bufMax))
            onsets = [onsets, i];
            allOnsets = [allOnsets, loc];
            last_detected_onset = loc;
        end
        
        x2_prev = x2;
    end
    
          
    % Update frame size from UI
%     drawnow limitrate
%     bufSize.value = round(bufSize.value);      
    
    
    
    if(frameEnd > 1.8*100000 && frameStart < 2.7*100000)
        debug = false;
    else
        debug = false;
    end
    
    
        % Use predefined 
%     while(~isempty(preOnsets) && preOnsets(1) <= frameEnd && preOnsets(1) >= frameStart)
        
%         o = preOnsets(1) - frameStart;
%         rCopyLen = o - (frameCpyInd - 1);
%         if(debug)
%             fprintf("\nCopying %d to readbuf\n", rCopyLen);
%             fprintf("Next onset: %d\n", preOnsets(1));
%             fprintf("Frame Copy Start: %d\n", frameCpyInd);
%             fprintf("Readbufind: %d\n", readBufInd);
%         end
%         
%         readBuf = copyToCircularBuf(readBuf, readBufInd, frame(frameCpyInd:frameCpyInd+rCopyLen-1));
%         readBufInd = readBufInd + rCopyLen;
%         if(debug)
%             fprintf("Readbufind: %d\n", readBufInd);
%             fprintf("\n");
%         end
%         frameCpyInd = frameCpyInd + rCopyLen;
%         frameBounds = [frameBounds, frameStart+frameCpyInd];
%         
%         preOnsets = preOnsets(2:end);

    frameCpyInd = 1;
    while(~isempty(onsets))
        rCopyLen = onsets(1) - (frameCpyInd - 1);
        if(debug)
            fprintf("\nCopying %d to readbuf\n", rCopyLen);
            fprintf("Next onset: %d\n", onsets(1));
            fprintf("Frame Copy Start: %d\n", frameCpyInd);
            fprintf("Readbufind: %d\n", readBufInd);
        end
        
        readBuf = copyToCircularBuf(readBuf, readBufInd, frame(frameCpyInd:frameCpyInd+rCopyLen-1));
        readBufInd = readBufInd + rCopyLen;
        if(debug)
            fprintf("Readbufind: %d\n", readBufInd);
            fprintf("\n");
        end
        frameCpyInd = frameCpyInd + rCopyLen;
        frameBounds = [frameBounds, frameStart+frameCpyInd];
        
        onsets = onsets(2:end);
        
        % flush
        if(debug)
            fprintf("\nFlushing %d..\n", readBufInd);
        end
            
        data = copyFromCircularBuf(readBuf, 1, readBufInd-1);
        zeroData(readBuf, 1, readBufInd-1);
        data = flip(data);
        
        if(debug)
%             printArray(data, length(data));
        end
        
                
        if(writeAmount == 0)
            boundaries = [length(data)];
            writeAmount = length(data);
        end
        
        if(overlap > 0)
            writeAmount = writeAmount + overlap + rCopyLen;
            overlap = 0;
        end
        
        if(writeBufWriteInd == -1)
%             writeAmount = writeAmount + rCopyLen;
%             boundaries = [boundaries, writeAmount];
            
            writeBufWriteInd = writeBufReadInd+rCopyLen;
            if(writeBufWriteInd > length(writeBuf))
                writeBufWriteInd = writeBufWriteInd - length(writeBuf);
            end
        end
        
        if(writeBufWriteInd == -2)
%             if(frameStart > 150000)
%                 fprintf("\n\nDOING\n\n");
%                 writeBufWriteInd = writeBufReadInd;
%             else
%             writeAmount = writeAmount + rCopyLen;
            writeBufWriteInd = writeBufReadInd+rCopyLen;
            if(writeBufWriteInd > length(writeBuf))
                writeBufWriteInd = writeBufWriteInd - length(writeBuf);
            end
%             end
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
        
        if(debug)
            fprintf("Writing %d into writeBuf\n", length(data));
            fprintf("WriteBuf WriteInd: %d\n", writeBufWriteInd);
            fprintf("WriteBuf ReadInd: %d\n", writeBufReadInd);
        end
        
        if(overlap == true)
            
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
        
        if(debug)
            fprintf("WriteBuf WriteInd: %d\n", writeBufWriteInd);
            fprintf("WriteBuf ReadInd: %d\n", writeBufReadInd);
        end
        

        
        writeAmount = writeAmount + length(data);
        boundaries = [boundaries, writeAmount];
        
        if(debug)
            
            if(writeBufWriteInd < writeBufReadInd)
                fprintf("writebuf fill: %d\n\n", length(writeBuf) - (writeBufReadInd - writeBufWriteInd));
            else
                fprintf("writebuf fill: %d\n\n", writeBufWriteInd - writeBufReadInd);
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
    
    rCopyLen = currFrameLen - frameCpyInd + 1;
    if(rCopyLen > 0)
        if(debug)
            fprintf("\nCopying %d to readbuf\n", rCopyLen);
            fprintf("Readbufind: %d\n", readBufInd);

        end
        readBuf = copyToCircularBuf(readBuf, readBufInd, frame(frameCpyInd:frameCpyInd+rCopyLen-1));
        readBufInd = readBufInd + rCopyLen;
        frameBounds = [frameBounds, frameEnd];
        
        if(debug)
            fprintf("Readbufind: %d\n", readBufInd);
            fprintf("\n");
        end
    end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
%     if(debug)
%         fprintf("\n\nFRAME RECEIVED\n");
%         fprintf("Frame len: %d\n", length(frame));
%     end
%     
%     rCopyLen = currFrameLen;
%     if(readBufInd + currFrameLen > bufSize.value)
%         rCopyLen = bufSize.value - readBufInd + 1;
%     end
%     rCopyLeftover = currFrameLen - rCopyLen;
%     
%     if(debug)
%         fprintf("CopyLen: %d\n", rCopyLen);
%         fprintf("Leftover: %d\n", rCopyLeftover);
%         fprintf("Read buf fill: %d\n", readBufInd-1);
%     end
%     
%     readBuf = copyToCircularBuf(readBuf, readBufInd, frame(1:rCopyLen));
%     readBufInd = readBufInd + rCopyLen;
%     if(debug)
%         fprintf("Copying %d to readBuf\n", rCopyLen);
%         fprintf("Read buf fill: %d\n", readBufInd-1);
% %         fprintf("Copy to Circular Buf: %d:%d\n", 1, rCopyLen);
% %         fprintf("ReadBuf Index: %d\n", readBufInd);
% %         printArray(readBuf, readBufInd);
%     end
%     
%     if(readBufInd >= bufSize.value)
%         data = copyFromCircularBuf(readBuf, 1, bufSize.value);
%         data = flip(data);
%         if(debug)
%             fprintf("Flushing...\n");
% %             fprintf("Data\n");
% %             printArray(data, -1);
%         end
%         if(writeBufWriteInd == -1)
%             writeBufWriteInd = writeBufReadInd+rCopyLen;
%             if(writeBufWriteInd > length(writeBuf))
%                 writeBufWriteInd = writeBufWriteInd - length(writeBuf);
%             end
%         end
%         
%         if(writeBufWriteInd < writeBufReadInd)
%             writefill = length(writeBuf) - (writeBufReadInd - writeBufWriteInd);
%         else
%             writefill = writeBufWriteInd - writeBufReadInd;
%         end
%         
%         if(length(writeBuf) - writefill < length(data)) 
%             fprintf("OVERLAP DETECTED\n");
%             fprintf("fill: %d\n", writefill);
%             fprintf("space: %d\n", length(writeBuf) - writefill);
%             fprintf("data len: %d\n", length(data));
%             return;
%         end
%         
%         writeBuf = copyToCircularBuf(writeBuf, writeBufWriteInd, data);
%         writeBufWriteInd = writeBufWriteInd + length(data);
%         if(writeBufWriteInd > length(writeBuf))
%             writeBufWriteInd = writeBufWriteInd - length(writeBuf);
%             if(writeBufWriteInd > writeBufReadInd)
%                 fprintf("ERROR: DATA OVERLAP\n");
%                 return;
%             end
%         end
%         
%         writeAmount = writeAmount + length(data);
%         boundaries = [boundaries, writeAmount];
%         if(debug)
%             fprintf("Writing %d into writeBuf\n", length(data));
%             
%             if(writeBufWriteInd < writeBufReadInd)
%                 fprintf("writebuf fill: %d\n", length(writeBuf) - (writeBufReadInd - writeBufWriteInd));
%             else
%                 fprintf("writebuf fill: %d\n", writeBufWriteInd - writeBufReadInd);
%             end
%         end
% %         fullOut = [fullOut; data];
%         readBuf = zeros(bufMax, 1);
%         readBufInd = 1;
%         
%         if(debug)
%             
% %             fprintf("WriteBuf Read Index: %d\n", writeBufReadInd);
% %             printArray(writeBuf, writeBufReadInd);
%         end
%         
%     end
%     
%     if(rCopyLeftover > 0)
%         readBuf = copyToCircularBuf(readBuf, readBufInd, frame(rCopyLen+1:currFrameLen));
%         readBufInd = readBufInd + rCopyLeftover;
%         if(readBufInd > bufSize.value)
%             readBufInd = readBufInd - bufSize.value;
%         end
%         if(debug)
%             fprintf("Copying %d to readBuf\n", rCopyLeftover);
%             fprintf("Readbuf fill: %d\n", readBufInd-1);
% %             fprintf("Copy to Circular Buf: %d:%d\n", rCopyLen+1, rCopyLen+rCopyLeftover);
% %             fprintf("ReadBuf Index: %d\n", readBufInd);
% %             printArray(readBuf, readBufInd)
%         end
%     end
% 
%         
% %     
% %     copyLen = bufSize - writeBufInd;
% %     if(copyLen > frameLen)
% %         copyLen = frameLen;
% %     end
% %     
% %     buf(bufWriteInd:bufWriteInd+copyLen) = frame(frameStart:frameStart+copyLen);
% %     bufWriteInd = bufWriteInd + copyLen;
% %     
% %     if(bufWriteInd >= bufMax)
% %         
% %     end
% %     
% %     leftOver = frameLen - copyLen;
% %         

    output = copyFromCircularBuf(writeBuf, writeBufReadInd, frameLen);
    zeroData(writeBuf, writeBufReadInd, frameLen);
    if(debug)
%         printArray(output, length(output));
        fprintf("WriteBuf WriteInd: %d\n", writeBufWriteInd);
        fprintf("WriteBuf ReadInd: %d\n", writeBufReadInd);
    end
    fullOut = [fullOut; output];
    
    if(writeBufReadInd > writeBufWriteInd)
        writeWrap = true;
    else
        writeWrap = false;
    end
    
    writeBufReadInd = writeBufReadInd + frameLen;
    if(writeBufReadInd > length(writeBuf))
        writeBufReadInd = writeBufReadInd - length(writeBuf);
        
        if(writeWrap && writeBufReadInd > writeBufWriteInd)
%             return;
%             fprintf("ERROR RAN OUT OF BUF1: %d\n", frameStart);
            writeBufWriteInd = -1;
            overlap = overlap + frameLen;
        elseif(~writeWrap)
%             fprintf("ERROR RAN OUT OF BUF2: %d\n", frameStart);
            writeBufWriteInd = -1;
            overlap = overlap + frameLen;
        end
    else
        if(writeWrap && writeBufWriteInd > writeBufReadInd)
%             if(debug)
%                 fprintf("ERROR RAN OUT OF BUF\n");
%             end
%             fprintf("ERROR RAN OUT OF BUF: %d\n", frameStart);
            writeBufWriteInd = -1;
            overlap = overlap + frameLen;
%             return;
        elseif(~writeWrap && writeBufReadInd > writeBufWriteInd)
%             fprintf("ERROR RAN OUT OF BUF3: %d\n", frameStart);
            writeBufWriteInd = -1;
            overlap = overlap + frameLen;
        end
    end
    if(debug)
        fprintf("WriteBuf WriteInd: %d\n", writeBufWriteInd);
        fprintf("WriteBuf ReadInd: %d\n", writeBufReadInd);
        
        fprintf("Reading %d from writebuf\n", frameLen);
        if(writeBufWriteInd < writeBufReadInd)
            fprintf("writebuf fill: %d\n", length(writeBuf) - (writeBufReadInd - writeBufWriteInd));
        else
            fprintf("writebuf fill: %d\n", writeBufWriteInd - writeBufReadInd);
        end
            
    end

    reversed = output;
    
%     output = mix.value*frame + (1-mix.value)*reversed;
    
    deviceWriter(reversed);
    

    frameStart = frameStart + frameLen;
end




% flush
if(debug)
    fprintf("\nFlushing %d..\n", readBufInd);
end

data = copyFromCircularBuf(readBuf, 1, readBufInd-1);
data = flip(data);


if(writeAmount == 0)
    boundaries = [length(data)];
    writeAmount = length(data);
end

if(overlap > 0)
    writeAmount = writeAmount + overlap + rCopyLen;
    overlap = 0;
end

if(writeBufWriteInd == -1)
    writeBufWriteInd = writeBufReadInd+rCopyLen;
    if(writeBufWriteInd > length(writeBuf))
        writeBufWriteInd = writeBufWriteInd - length(writeBuf);
    end
end


writeAmount = writeAmount + length(data);
boundaries = [boundaries, writeAmount];

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


if(debug)
    fprintf("Writing %d into writeBuf\n", length(data));

    if(writeBufWriteInd < writeBufReadInd)
        fprintf("writebuf fill: %d\n\n", length(writeBuf) - (writeBufReadInd - writeBufWriteInd));
    else
        fprintf("writebuf fill: %d\n\n", writeBufWriteInd - writeBufReadInd);
    end
end
%         fullOut = [fullOut; data];
readBuf = zeros(bufMax, 1);
readBufInd = 1;




if(writeBufWriteInd < writeBufReadInd)
    writeBufLen = length(writeBuf) - (writeBufReadInd - writeBufWriteInd);
else
    writeBufLen = writeBufWriteInd - writeBufReadInd;
end
rest = copyFromCircularBuf(writeBuf, writeBufReadInd, writeBufLen);

fullOut = [fullOut; rest];
deviceWriter(rest);
fprintf("DONE\n");

t = linspace(0, length(audio)/fs, length(audio));
figure;
subplot(211);
hold on;
plot(t, audio);
for i=allOnsets
    xline(i/fs, 'm');
end
title("Original Signal w/ Onsets");
xlabel("Time (s)");
ylabel("Amplitude");
legend(["Original Signal", "Detected Onsets"]);

t = linspace(0, length(fullOut)/fs, length(fullOut));
subplot(212);
hold on;
plot(t, fullOut);
for b=boundaries
    xline(b/fs, 'm');
end
% for b=frameBounds
%     xline(b, 'm');
% end
title("Output Signal w/ Frame Boundaries");
xlabel("Time (s)");
ylabel("Amplitude");
legend(["Output Signal", "Frame Boundaries"]);



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

function retBuf = zeroData(buf, ind, len)
    firstLen = len;
    if(ind + firstLen > length(buf))
        firstLen = length(buf) - ind + 1;
    end
    secondLen = len - firstLen;
    
    buf(ind:ind+firstLen-1) = zeros(length(firstLen), 1);
    buf(1:secondLen) = zeros(length(secondLen), 1);
    
    retBuf = buf;
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
