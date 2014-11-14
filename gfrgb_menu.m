function varargout = gfrgb_menu(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gfrgb_menu_OpeningFcn, ...
                   'gui_OutputFcn',  @gfrgb_menu_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before gfrgb_menu is made visible.
function gfrgb_menu_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for gfrgb_menu
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = gfrgb_menu_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in button_tifffs.
function button_tifffs_Callback(hObject, eventdata, handles)
global Film_Img;

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
imshow(Film_Img, 'Parent', handles.axes_FileImg);
guidata(hObject, handles);


% --- Executes on button press in button_zoomin.
function button_zoomin_Callback(hObject, eventdata, handles)
% Acquire vars
global Film_Img Film_Area;

% Update status test
set(handles.text_update, 'String', 'Click and drag a region to zoom into');
guidata(hObject, handles);

% Drag rectangle across desired area within boundaries of figure
try
rect = getrect;
xmin = round(rect(1)); ymin = round(rect(2));
width = round(rect(3)); height = round(rect(4));
while ( ~( xmin>0 && ymin>0 && xmin+width<=length(Film_Img(1,:,1)) && ymin+height<=length(Film_Img(:,1,1)) ) )
    status_string = 'Please keep the range within the image';
    set(handles.text_update, 'String', status_string);
    rect = getrect;
    xmin = round(rect(1)); ymin = round(rect(2));
    width = round(rect(3)); height = round(rect(4));
end
status_string = strcat('width: ', num2str(width), ', height: ', num2str(height));
line([xmin xmin+width],[ymin ymin])
line([xmin+width xmin+width],[ymin ymin+height])
line([xmin xmin+width],[ymin+height ymin+height])
line([xmin xmin],[ymin ymin+height])

% Replace image with zoom
Film_Area = Film_Img(ymin:ymin+height,xmin:xmin+width,:);
imshow(Film_Area, 'Parent', handles.axes_FileImg);
catch
    status_string = 'Canceled';
end
% Update status test;
set(handles.text_update, 'String', status_string);

guidata(hObject, handles);


% --- Executes on button press in button_zoomout.
function button_zoomout_Callback(hObject, eventdata, handles)
% Acquire vars
global Film_Img;

% Redisplay original file image, update statue
imshow(Film_Img, 'Parent', handles.axes_FileImg);
status_string = 'File zoomed out';
set(handles.text_update, 'String', status_string);
guidata(hObject, handles);


% --- Executes on button press in text_calculate.
function text_calculate_Callback(hObject, eventdata, handles)
% Acquire vars
global Film_Area;

% Area-pixel reconstruction
CourseAreaSide = 2;
MxRows = length(Film_Area(:,1,1))-(CourseAreaSide-1);
MxCols = length(Film_Area(1,:,1))-(CourseAreaSide-1);
Mx = zeros(MxRows, MxCols, 3);
vertex_area = zeros(3, 3);
vertex = zeros(3, 3);

% Main Loop
hold on
for channelNum=1:3
   % Construct the values of the new matrix by analyzing each area
   for j = 1:MxRows
     for i = 1:MxCols
       Mx(j, i, channelNum) = sum(sum(Film_Area(j:(j+(CourseAreaSide-1)), i:(i+(CourseAreaSide-1)), channelNum)))/(CourseAreaSide^2);
     end
   end

  % Course-grain peak location
  vertex_area(3, channelNum) = min(min(Mx(:, :, channelNum)));
  for j = 1:MxRows
    for i = 1:MxCols
      if (Mx(j, i, channelNum) == vertex_area(3, channelNum))
          vertex_area(1, channelNum) = j; vertex_area(2,  channelNum) = i;
      end
    end
  end
  
  % Global peak location at peak of side x side vertex_area
  vertex(3,channelNum) = min(min(Film_Area(vertex_area(1, channelNum):vertex_area(1, channelNum)+CourseAreaSide-1, ...
      vertex_area(2, channelNum):vertex_area(2, channelNum)+CourseAreaSide-1, channelNum)));
  for j = 1:CourseAreaSide
    for i = 1:CourseAreaSide
      if (Film_Area(vertex_area(1,channelNum)+j-1, vertex_area(2,channelNum)+i-1, channelNum) == vertex(3,channelNum))
          vertex(1,channelNum) = j + vertex_area(1,channelNum) - 1;
          vertex(2,channelNum) = i + vertex_area(2,channelNum) - 1;
      end
    end
  end
end

gfrgb_gui