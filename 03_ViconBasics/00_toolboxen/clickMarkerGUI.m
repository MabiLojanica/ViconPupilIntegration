function marker = clickMarkerGUI(img,numMarker,withLine,withText)  
    %show image
    handle = figure();
    clf;
    imhandle = image(img);
    axis('ij'), hold on;
    
    
    i = 1;
    while i <= numMarker
        [x,y,but] = ginput(1); 	% Get next point.

        if (but==1)
            marker(i,:) = [x y];
            k(i) = plot(x,y,'r+');         % Mark coordinates on image.
            if(i>1 && withLine)
                l(i) = line ([marker(i-1,1) marker(i,1)],[marker(i-1,2) marker(i,2)],'Color',[1 0 1]);
            end
            
            if withText
                h(i) = text(x+3,y-3,sprintf('M%.d [%.1f, %.1f]',i,x,y),'Color',[1 0 0], ...
                'FontSize',6); 
            end
            
            i = i+1; 
        elseif i > 1
            i = i-1;
            delete(k(i));
            if(i>1)
                delete(l(i));
            end
            marker(i,:) = [];
        else
            i = 1;
        end
    end
    
    [x,y,but] = ginput(1); 	% wait for last click.
    delete(handle);    
   end
