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
    try gui_mainfcn(gui_State, varargin{:}); catch; end
end
% End initialization code - DO NOT EDIT



% --- Executes just before gfrgb_menu is made visible.
function gfrgb_menu_OpeningFcn(hObject, eventdata, handles, varargin)
% Acquire gloabal variables
global Film_Img Film_FileName;
Film_Img = 1;
Film_FileName = '';

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
global Film_Img Film_Area Film_Area_Prev Film_FileName rect;

% Image Single-selection, set as cell array
[Film_FileName, Film_FilePath, Img_Index] = uigetfile('*.tif', ...
    'Choose image file', 'MultiSelect', 'off');

% If successful selection
if ~isempty(Film_FileName)
    Film_FileName = strcat(Film_FilePath, Film_FileName);

    % Check filenames for tiff-type extension
    validFile = 1;
    [dirPath, fileBaseName, extType] = fileparts(Film_FileName);
    if (strcmpi(extType, '.tif') == 0)
        % Display fail status and quit loop
        status_string = 'Selection is not a valid TIFF file';
        validFile = 0;
        return
    else
        Film_FileName = strcat(dirPath, '/', fileBaseName, extType);
    end
    
    % If file is tiff
    if ( validFile )
        % Display image on axes 
        Film_Img = imread(Film_FileName); % Or only this one
        imshow(Film_Img, 'Parent', handles.axes_FileImg);
        
        % Display filename and success status
        set(handles.text_filename, 'String', Film_FileName);
        status_string = 'Image loaded';
        
        % Preset selection rectangle, selection area as whole original image,
        % and previous image view as whole original image
        rect = 0; Film_Area = Film_Img;
        Film_Area_Prev = Film_Area;
    end
else
    % Image selection canceled
    status_string = 'Canceled file selection';
end
set(handles.text_update, 'String', status_string);
guidata(hObject, handles);


% --- Executes on button press in button_zoomin.
function button_zoomin_Callback(hObject, eventdata, handles)
% Acquire global variables
global Film_Area_Prev Film_Area Film_FileName rect;

% If filename string is empty, assume no image
if isempty(Film_FileName)    
    status_string = 'Cannot zoom in; no selected image';
else
    % Update status test
    set(handles.text_update, 'String', 'Click and drag a region; hold Shift for a square');
    guidata(hObject, handles);

    % Drag rectangle across desired area within boundaries of figure
    if ~( rect==0 ) Film_Area_Prev = Film_Area; end % Unzoomed
    
    % Continuously attempt region selection until "good" selection
    try 
        rect = getrect(handles.axes_FileImg);
        xmin = round(rect(1)); ymin = round(rect(2)); width = round(rect(3)); height = round(rect(4));
   
        % Can't be outside image boundaries
        while ( ~( xmin>0 && ymin>0 && xmin+width<=length(Film_Area(1,:,1)) && ymin+height<=length(Film_Area(:,1,1)) ) )
            status_string = 'Please keep the range within the image';
            set(handles.text_update, 'String', status_string);
            rect = getrect;
            xmin = round(rect(1)); ymin = round(rect(2)); width = round(rect(3)); height = round(rect(4));
        end
        % Output successful selection boundaries as status
        status_string = strcat(num2str(width), 'x', num2str(height), ...
            ' region at (', num2str(xmin), ', ', num2str(ymin), ')');

        % Replace image with zoom
        Film_Area = Film_Area_Prev(ymin:ymin+height, xmin:xmin+width,:);
        cla(handles.axes_FileImg, 'reset');
        imshow(Film_Area, 'Parent', handles.axes_FileImg);
    catch
        status_string = 'Canceled'; % If no rectangle (possible feature?)
    end
end
% Update status test;
set(handles.text_update, 'String', status_string);

guidata(hObject, handles);


function var_side_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function var_side_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button_zoomout.
function button_zoomout_Callback(hObject, eventdata, handles)
% Acquire gloabal variables
global Film_Img Film_Area Film_Area_Prev Film_FileName rect;

% Redisplay original file image if one exists  
if isempty(Film_FileName)
    % Update failure status text
    status_string = 'Cannot zoom out; no selected image';
    set(handles.text_update, 'String', status_string);
else
    if ( rect==0 ) % unzoomed
        status_string = 'Image already zoomed out';
        set(handles.text_update, 'String', status_string);
    else % reiterate end of button_tifffs_callback
        rect = 0; Film_Area = Film_Img;
        Film_Area_Prev = Film_Area;
        cla(handles.axes_FileImg,'reset');
        imshow(Film_Img, 'Parent', handles.axes_FileImg);
        status_string = 'Image zoomed out';
        set(handles.text_update, 'String', status_string);
    end
end
guidata(hObject, handles);


% --- Executes on button press in text_calculate.
function text_calculate_Callback(hObject, eventdata, handles)
% Acquire vars
global Film_Area vertex Film_FileName rect dpi;

% Check for image in axes
if isempty(Film_FileName)
    % Display unsuccessful calculation status
    status_string = 'Cannot calculate; no selected image';
    set(handles.text_update, 'String', status_string);
    guidata(hObject, handles);
else % Check with user if unzoomed
    choice_confirm = 1;
    if ( rect == 0 )
        % Confirm calculations for unzoomed image
        choice = questdlg('Image unzoomed, proceed?', 'Continue?', 'Yes', 'No', 'No');
        switch choice
            case 'No'
                choice_confirm = 0;
        end
    end
    
    % Immediately quit if user chooses "No"
    if ( ~choice_confirm ) return; end
    
    %{
            Algorithm for finding peak pixel coordinate (y, x, rgb_i)
    
      For R, G, and B channels of 16-bit grayscale, 0 is absolute black
      and 2^16 = 65536 is white.  Irradiated film is dark, thus the peak
      is a minimim value.

      For every possible location of an mxm matrix on the selected region
      (Film_Area), an average value is taken of the m^2 cells.  The (at
      the moment, latest) global minimum of these mxm averages is assumed
      to be the location of the global minimum coordinate, so the (again,
      latest) cell is found with respect to the selected region:
    
                     ( vertex(1, rgb_i), vertex(2, rgb_i) )
    %}
    % Gather/declare vars
    dpi = str2double(get(handles.var_dpi,'String'));
    CourseAreaSide = str2num(get(handles.var_side,'String'));
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
            Mx(j, i, channelNum) = sum(sum(Film_Area(j:(j+(CourseAreaSide-1)), ...
           i:(i+(CourseAreaSide-1)), channelNum)))/(CourseAreaSide^2);
          end
        end

      % Course-grain peak location
      vertex_area(3, channelNum) = min(min(Mx(:, :, channelNum)));
      for j = 1:MxRows
        for i = 1:MxCols
          if (Mx(j, i, channelNum) == vertex_area(3, channelNum))
            %if ( ( i>3 || i<MxCols-3 ) && ( j>3 || j<MxRows-3 ) ) % 3 pixel side buffer
              vertex_area(1, channelNum) = j; vertex_area(2,  channelNum) = i;
            %end
          end
        end
      end
  
      % Global peak location at peak of side x side vertex_area
      vertex(3,channelNum) = min(min(Film_Area(vertex_area(1, ...
          channelNum):vertex_area(1, channelNum)+CourseAreaSide-1, ...
          vertex_area(2, channelNum):vertex_area(2, channelNum)+CourseAreaSide-1, ...
          channelNum)));
      for j = 1:CourseAreaSide
        for i = 1:CourseAreaSide
          if (Film_Area(vertex_area(1,channelNum)+j-1, vertex_area(2,channelNum)+i-1, channelNum) == vertex(3,channelNum))
            vertex(1,channelNum) = j + vertex_area(1,channelNum) - 1;
            vertex(2,channelNum) = i + vertex_area(2,channelNum) - 1;
          end
        end
      end
    end

    % Open results page with global vars: Film_Area, vertex
    % Feature at some point: Film_Img for continuity of data beyond
    % selected region
    gfrgb_gui
end
