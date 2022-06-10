function [setOfFrames,indicies] = sepTracks(frame,box,labels)

if (~isempty(box) && ~isempty(labels))

 ss=size(frame);
 sb=size(box);
 ...n of tracks
 m=sb(1);
 setOfFrames=uint8(zeros(ss(1),ss(2),3,m));

 if(m ~= 1)
 indicies=cell(1,m);
  for i=1:m 
  x=box(i,1);
  y=box(i,2);
  width=box(i,3);
  height=box(i,4);

  if( ~((y+height)>ss(1)) && ~((x+width>ss(2))) )
    
    newFrame=uint8(zeros(ss(1),ss(2),3));
    newFrame(y:y+height,x:x+width,1)=frame(y:y+height,x:x+width,1);
    newFrame(y:y+height,x:x+width,2)=frame(y:y+height,x:x+width,2);
    newFrame(y:y+height,x:x+width,3)=frame(y:y+height,x:x+width,3);
    setOfFrames(:,:,:,i)=newFrame(:,:,:);
    indicies{i}=[str2num(labels{i}),i];
  end

 end

 else
indicies=cell(1,1);
setOfFrames(:,:,:,1)=frame(:,:,:);
indicies{1}=[str2num(labels{1}),1];
end

else
indicies=cell(1,1);
setOfFrames=uint8(zeros(480,720,3,1));
indicies{1}=[-1,1];
end



end
