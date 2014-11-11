%{
  Gafchromic-RGB Analyzer

  Allows user to view max/min values of RGB channels in
  selected region of exposed film images.
%}

%% Image Acquisition
% Image Multi-selection, set as cell array
[imgFileNames, imgFilePath] = uigetfile('*.tif', 'Choose image file', 'MultiSelect', 'on');
imgFileNames = cellstr(strcat(imgFilePath,'\',imgFileNames));
% Quit if none selected
if isempty(imgFileNames)
    clear
    return
end
% Check filenames for tiff-type extension
for i = 1:length(imgFileNames)
  [dirPath, fileBaseName{i}, extType] = fileparts(imgFileNames{i});
  if (strcmpi(extType, '.tif') == 0)
    fprintf('File is not a tiff (*.tif) image.\n\n')
    clear
    return
  end
  imgFileNames{i} = strcat(dirPath, fileBaseName{i}, extType);
end
% Average multiple selections
RGB_Img = imread(imgFileNames{1}); % Or only this one
if length(imgFileNames) > 1
  for i = 2:length(imgFileNames)
    RGB_Img = imadd(RGB_Img,imread(imgFileNames{i}));
  end
  RGB_Img = RGB_Img/length(imgFileNames);
end

%% Image Display and Selection
% Create loop of area selection dialogs
good_area_choice = 0;
while (good_area_choice == 0)
    
  % Plot image in axes
  imshow(RGB_Img)
  
  % Drag rectangle across desired area and create temp lines
  rect = getrect;
  xmin = round(rect(1)); ymin = round(rect(2));
  width = round(rect(3)); height = round(rect(4));
  line([xmin xmin+width],[ymin ymin])
  line([xmin+width xmin+width],[ymin ymin+height])
  line([xmin xmin+width],[ymin+height ymin+height])
  line([xmin xmin],[ymin ymin+height])

  % Construct a questdlg with three options
  choice = questdlg('Are you sure of this selection?', 'Area selection', 'Yes', 'No', 'No');
  % Handle response
  switch choice
    case 'Yes'
      good_area_choice = 1;
    case 'No'
      continue;
  end
end
% Work now only with selected area
RGB_Area = RGB_Img(ymin:ymin+height,xmin:xmin+width,:);

%% Image analysis
% Get mini-matrix dimensions
area_dlg_prompt = {'Enter averaging area length:','Enter averaging area height:'};
area_dlg_title = 'Input';
area_dlg_dims = {'2','2'};
area_dlg_dims = inputdlg(area_dlg_prompt,area_dlg_title,1,area_dlg_dims);
xAreaLength = str2num(area_dlg_dims{1}); yAreaLength = str2num(area_dlg_dims{2});
% Area-pixel reconstruction
newMxRows=height-(yAreaLength-1);
newMxCols=width-(xAreaLength-1);
newMx=zeros(newMxRows,newMxCols,3);
% Main Loop
RGB_i = {'Red' 'Green' 'Blue'};
for channelNum=1:3
  % Single-pixel reconstruction
  fprintf('\n%s channel:\n==============\n', RGB_i{channelNum});
  CoordMinima(channelNum) = min(min(RGB_Area(:,:,channelNum)));
  CoordMaxima(channelNum) = max(max(RGB_Area(:,:,channelNum)));
  % Match each pixel value to min/max value
  for i=1:height
    for j=1:width
      if (RGB_Area(i,j,channelNum) == CoordMinima(channelNum))
        fprintf('(%d,%d) is the PIXEL minima %d.\n',j,i,CoordMinima(channelNum));
      end
      if (RGB_Area(i,j,channelNum) == CoordMaxima(channelNum))
        fprintf('(%d,%d) is the PIXEL maxima %d.\n',j,i,CoordMinima(channelNum));
      end
    end
  end
  % Construct the values of the new matrix by analyzing each area
  for i=1:newMxRows
    for j=1:newMxCols
      newMx(i,j,channelNum)=sum(sum(RGB_Area(i:(i+(yAreaLength-1)),j:(j+(xAreaLength-1)), channelNum)))/(xAreaLength*yAreaLength);
    end
  end
  % Minima/Maxima of all areas
  AreaMinima(channelNum) = min(min(newMx(:,:,channelNum)));
  AreaMaxima(channelNum) = max(max(newMx(:,:,channelNum)));
  for i=1:newMxRows
    for j=1:newMxCols
      if (newMx(i,j,channelNum) == AreaMinima(channelNum))
        fprintf('(%d,%d) is the %dx%d AREA minima %d.\n',j,i,xAreaLength,yAreaLength,AreaMinima(channelNum));
      end
      if (newMx(i,j,channelNum) == AreaMaxima(channelNum))
        fprintf('(%d,%d) is the %dx%d AREA maxima %d.\n\n',j,i,xAreaLength,yAreaLength,AreaMinima(channelNum));
      end
    end
  end

  % Construct 3 subplots, for each analysis
  subplot(3,1,channelNum)
  surf(RGB_Area(:,:,channelNum), double(RGB_Area(:,:,channelNum)))
  %contour(RGB_Area(:,:,channelNum))
  titleString = sprintf('%s Channel', RGB_i{channelNum}); title(titleString);
end
