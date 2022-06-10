function [frame] = filBox(maskk,box)
 if ~isempty(box)
 ss=size(maskk);
 sb=size(box);
 disp(size(sb))
 m=sb(1);
 frame=uint8(zeros(ss(1),ss(2),3));

 x=box(1,1);
 y=box(1,2);
 width=box(1,3);
 height=box(1,4);

  for i=1:m   
   if( ~((y+height)>ss(1)) && ~((x+width>ss(2))) )
   x=box(i,1);
   y=box(i,2);
   width=box(i,3);
   height=box(i,4);
   frame(y:y+height,x:x+width,1)=ones(height+1,width+1);
   frame(y:y+height,x:x+width,2)=ones(height+1,width+1);
   frame(y:y+height,x:x+width,3)=ones(height+1,width+1);
   else   
  remainX=(x+width)-ss(1);
  remainY=(y+height)-ss(2);
  disp("in")
  frame(y:y+remainY,x:x+remainX,1)=ones(remainY+1,remainX+1);
  frame(y:y+remainY,x:x+remainX,2)=ones(remainY+1,remainX+1);
  frame(y:y+remainY,x:x+remainX,3)=ones(remainY+1,remainX+1);
   end
  end 


 else
     frame=maskk;
 end

end