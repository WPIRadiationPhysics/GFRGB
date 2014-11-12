%{
  Gafchromic-RGB Analyzer

  Allows user to view max/min values of RGB channels in
  selected region of exposed film images.
%}

%% Initialize Global Vars
global Film_Area vertex;

%% Image Acquisition
% Image Multi-selection, set as cell array
[Film_FileName, Film_FilePath] = uigetfile('*.tif', 'Choose image file', 'MultiSelect', 'on');
Film_FileName = cellstr(strcat(Film_FilePath, '\', Film_FileName));

% Quit if none selected
if isempty(Film_FileName)
    clear; return;
end

% Check filenames for tiff-type extension
for i = 1:length(Film_FileName)
  [dirPath, fileBaseName{i}, extType] = fileparts(Film_FileName{i});
  if (strcmpi(extType, '.tif') == 0)
    fprintf('File is not a tiff (*.tif) image.\n\n')
    clear
    return
  end
  Film_FileName{i} = strcat(dirPath, fileBaseName{i}, extType);
end
Film_Img = imread(Film_FileName{1}); % Or only this one

% Average multiple selections
% if length(imgFileNames) > 1
%   for i = 2:length(imgFileNames)
%     RGB_Img = imadd(RGB_Img,imread(imgFileNames{i}));
%   end
%   RGB_Img = RGB_Img/length(imgFileNames);
% end

%% Image Display and Selection
% Create loop of area selection dialogs
good_area_choice = 0;
while (good_area_choice == 0)
  % Plot image in axes
  imshow(Film_Img)
  
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
Film_Area = Film_Img(ymin:ymin+height,xmin:xmin+width,:);

%% Image analysis
% Area-pixel reconstruction
CourseAreaSide = 2;
MxRows = height-(CourseAreaSide-1);
MxCols = width-(CourseAreaSide-1);
Mx = zeros(MxRows, MxCols,3);
vertex_area = zeros(3,3);
vertex = zeros(3,3);

% Main Loop
RGB_i = {'Red' 'Green' 'Blue'};
for channelNum=1:3
   % Construct the values of the new matrix by analyzing each area
   for j=1:MxRows
     for i=1:MxCols
       Mx(j, i, channelNum) = sum(sum(Film_Area(j:(j+(CourseAreaSide-1)),i:(i+(CourseAreaSide-1)), channelNum)))/(CourseAreaSide^2);
     end
   end

  % Course-grain peak location
  vertex_area(3,channelNum) = min(min(Mx(:,:,channelNum)));
  for j=1:MxRows
    for i=1:MxCols
      if (Mx(j,i,channelNum) == vertex_area(3,channelNum))
          vertex_area(1,channelNum) = j; vertex_area(2,channelNum) = i;
      end
    end
  end
  
  % Global peak location at peak of side x side vertex_area
  vertex(3,channelNum) = min(min(Film_Area(vertex_area(1,channelNum):vertex_area(1,channelNum)+CourseAreaSide-1, ...
      vertex_area(2,channelNum):vertex_area(2,channelNum)+CourseAreaSide-1, channelNum)));
  for j=1:CourseAreaSide
    for i=1:CourseAreaSide
      if (Film_Area(vertex_area(1,channelNum)+j-1, vertex_area(2,channelNum)+i-1, channelNum) == vertex(3,channelNum))
          vertex(1,channelNum) = j + vertex_area(1,channelNum) - 1;
          vertex(2,channelNum) = i + vertex_area(2,channelNum) - 1;
      end
    end
  end
end

%% Initialize Analyzer GUI
close
gfrgb_gui