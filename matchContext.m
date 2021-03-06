function context_match = matchContext(matchimg,inputimg,selection)
%returns the translaion and scale of the best context match
%between matchimg and the original inputimg - removed selection

disp('beginning context match...');

%pixels within this radius are a part of the input's context
CONTEXT_RADIUS = 80;

%valid scales that can be applied to the match image
%VALID_SCALE = ([.81,.90,1]);
VALID_SCALE = ([.81,1])
%scales the translational error
TRANSLATE_ERROR = 1;

%amount of pixels to increment at each translation
PIXEL_JUMP = 10;

%scales the texture descriptor error
TEXTURE_ERROR = 1;

disp('reading files...');

%read files
% match = imread(matchimg);
% input = imread(inputimg);
match = matchimg;
input = inputimg;
insize = size(input);

disp('building context mask...');

%build context matrix
context = zeros(insize(1),insize(2));

%boundaries of context
c_x = ([-1 -1]);
c_y = ([-1 -1]);


for i=1:insize(1)
    for j=1:insize(2)
        if(selection(i,j)==0)
            for k=max(1,i-CONTEXT_RADIUS):min(i+CONTEXT_RADIUS,insize(1))
                for l=max(1,j-CONTEXT_RADIUS):min(j+CONTEXT_RADIUS,insize(2))
                    d = sqrt((i-k)^2+(j-l)^2);
                    if(d<=CONTEXT_RADIUS && (i~=k && j~=l))
                        context(k,l) = 1;
                        if(c_x(1)==-1 || k<c_x(1))
                            c_x(1)=k;
                        end
                        if(c_x(2)==-1 || k>c_x(2))
                            c_x(2)=k;
                        end
                        if(c_y(1)==-1 || l<c_y(1))
                            c_y(1)=l;
                        end
                        if(c_y(2)==-1 || l>c_y(2))
                            c_y(2)=l;
                        end
                    end
                end
            end
        end
    end
end

disp('finding minimum ssd...');

%now compute the SSD across all valid translations and scales
%find minimum SSD
minSSD = Inf;
sz = size(VALID_SCALE);

cform = makecform('srgb2lab');
input = applycform(input,cform);

context_match = struct('valid',0);

for i=1:sz(2)
    scl = imresize(match, VALID_SCALE(i));
    match = applycform(match,cform);
    sclsz = size(scl);
    xt=(c_x(2)-sclsz(1));
    while(xt<=(c_x(1)-1))
        disp([num2str(xt) '/' num2str(c_x(1)-1)]);
        
        yt=(c_y(2)-sclsz(2));
        while(yt<=(c_y(1)-1))      
%                 disp(['    ' num2str(yt) '/' num2str(c_y(1)-1)]);
                x = getContextSSD(scl,xt,yt,input,context);
                x = x + xt*TRANSLATE_ERROR + yt*TRANSLATE_ERROR;
                x = x + TEXTURE_ERROR*getContextTFilt(scl,xt,yt,input,context);
                if(x<minSSD)
                    disp('low ssd found');
                    minSSD=x;
                    context_match = struct('x_t',xt,'y_t',yt,'scale',VALID_SCALE(i),'context_mask',context,'valid',1);       
                end
                yt = yt + PIXEL_JUMP;
        end
        xt = xt + PIXEL_JUMP;
    end
end
end