function varargout = gfrgb_gui(varargin)
% Begin initialization code
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gfrgb_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @gfrgb_gui_OutputFcn, ...
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
% End initialization code

function gfrgb_gui_OutputFcn(hObject, eventdata, handles, varargin)

% Draw circle of selected radius
function circleDraw(hObject, handles)
global vertex;
r = str2double(get(handles.var_r, 'String'));
dpi = str2double(get(handles.var_dpi, 'String'));
r_px = r*dpi/25.4; r_pxTol = r*dpi/25.4; % get r +- rTol in px

% Create circle with, well, rectangle()
rectangle('Position', [vertex(2)-r_px vertex(1)-r_px 2*r_px 2*r_px], ...
'Curvature', [1 1], 'Parent', handles.axes_FilmArea)
% Update vertex text
vertex_str = strcat('(', num2str(vertex(2,1)), ',', num2str(vertex(1,1)), ')');
set(handles.text_vertex, 'String', vertex_str);

function plot_OD(hObject, handles)
% Acquire vars
global Film_Area vertex I;
r = str2double(get(handles.var_r,'String'));
rTol = str2double(get(handles.var_rTol,'String'));
dpi = str2double(get(handles.var_dpi,'String'));
dots = r*dpi/25.4; dotsTol = rTol*dpi/25.4; % get r +- rTol in px
rgb = get(handles.text_rgb, 'String');
if ( strcmp(rgb,'Red') ) rgb_i=1; elseif ( strcmp(rgb, 'Green') ) rgb_i=2; else rgb_i=3; end
I_numpoints = 360; %100 data points
I = zeros(I_numpoints);
dtheta = 2*pi/I_numpoints;
theta=0:dtheta:2*pi;

% Loop through whole angle
for i_theta=1:1:I_numpoints;
    I_y = round(vertex(1,rgb_i) - dots*sin(theta(i_theta)));
    I_x = round(vertex(2,rgb_i) + dots*cos(theta(i_theta)));
    try I(i_theta) = Film_Area(I_y, I_x, rgb_i); catch; end
end
plot(1:360, I, 'Parent', handles.axes_OD);


% --- Executes just before gfrgb_gui is made visible.
function gfrgb_gui_OpeningFcn(hObject, eventdata, handles, varargin)
global Film_Area;
% Display Red channel of selected area
imshow(Film_Area(:,:,1), 'Parent', handles.axes_FilmArea);
hold on; circleDraw(hObject, handles); hold off;
plot_OD(hObject, handles)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end


% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
                     ['Close ' get(handles.figure1,'Name') '...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end
delete(handles.figure1)


% --- Executes during object creation, after setting all properties.
function slider_r_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function var_r_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function var_rTol_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function slider_rTol_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function var_dpi_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in toggle_red.
function toggle_red_Callback(hObject, eventdata, handles)
if ( get(hObject, 'Value') == 1 )
    global Film_Area vertex;

    set(handles.toggle_green, 'Value', 0);
    set(handles.toggle_blue, 'Value', 0);
    set(handles.text_rgb, 'String', 'Red');
    
    % Display Red channel of selected area
    imshow(Film_Area(:,:,1), 'Parent', handles.axes_FilmArea);
    hold on;
    circleDraw(hObject, handles)
    hold off;
end
guidata(hObject, handles);


% --- Executes on button press in toggle_green.
function toggle_green_Callback(hObject, eventdata, handles)
if ( get(hObject, 'Value') == 1 )
    global Film_Area vertex;

    set(handles.toggle_red, 'Value', 0);
    set(handles.toggle_blue, 'Value', 0);
    set(handles.text_rgb, 'String', 'Green');
    
    % Display Green channel of selected area
    imshow(Film_Area(:,:,2), 'Parent', handles.axes_FilmArea);
    hold on;
    circleDraw(hObject, handles)
    hold off;
end
guidata(hObject, handles);


% --- Executes on button press in toggle_blue.
function toggle_blue_Callback(hObject, eventdata, handles)
if ( get(hObject, 'Value') == 1 )
    global Film_Area vertex;

    set(handles.toggle_red, 'Value', 0);
    set(handles.toggle_green, 'Value', 0);
    set(handles.text_rgb, 'String', 'Blue');
    vertex_str = strcat('(', num2str(vertex(2,3)), ',', num2str(vertex(1,3)), ')');
    set(handles.text_vertex, 'String', vertex_str);
    
    % Display Blue channel of selected area
    imshow(Film_Area(:,:,3), 'Parent', handles.axes_FilmArea);
    hold on;
    circleDraw(hObject, handles)
    hold off;
end
guidata(hObject, handles);


% --- Executes on slider_r movement
function slider_r_Callback(hObject, eventdata, handles)
global Film_Area

% Acquire state variables
slider_r = get(hObject,'Value');
rgb = get(handles.text_rgb, 'String');
if ( strcmp(rgb,'Red') ) i=1; elseif ( strcmp(rgb, 'Green') ) i=2; else i=3; end
set(handles.var_r,'String', slider_r);

% Display R/G/B channel of selected area
imshow(Film_Area(:,:,i), 'Parent', handles.axes_FilmArea);
hold on;
circleDraw(hObject, handles)
hold off;
guidata(hObject, handles);


% --- Executes on r input
function var_r_Callback(hObject, eventdata, handles)
r = str2double(get(hObject,'String'));
if ( r >= 0 && r <= get(handles.slider_r,'Max') )
    set(handles.slider_r,'Value', r);
    guidata(hObject, handles);
else
    set(handles.var_r,'String', get(handles.slider_r,'Value '));
    guidata(hObject, handles);
end


% --- Executes on slider_rTol movement
function slider_rTol_Callback(hObject, eventdata, handles)
slider_rTol = get(hObject,'Value');
set(handles.var_rTol,'String', slider_rTol);
guidata(hObject, handles);


% --- Executes on slider_dpi movement
function slider_dpi_Callback(hObject, eventdata, handles)
slider_dpi = get(hObject,'Value');
set(handles.var_dpi,'String', slider_dpi);
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function slider_dpi_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on button press in button_recalculate.
function button_recalculate_Callback(hObject, eventdata, handles)
global Film_Area
% Acquire state variables
slider_r_max = get(handles.slider_r, 'Max');
r = str2double(get(handles.var_r,'String'));
rTol = str2double(get(handles.var_rTol,'String'));
dpi = str2double(get(handles.var_dpi,'String'));
rgb = get(handles.text_rgb, 'String');
if ( strcmp(rgb,'Red') ) rgb_i=1; elseif ( strcmp(rgb, 'Green') ) rgb_i=2; else rgb_i=3; end

% Check for numeric input
if ( isnan(r) ) set(handles.var_r,'String',0); errordlg('r must be a number', 'Error'); end
if ( isnan(rTol) ) set(handles.var_rTol,'String',1); errordlg('Tolerance must be a number', 'Error'); end
if ( isnan(dpi) ) set(handles.var_dpi,'String',72); errordlg('dpi must be a number', 'Error'); end

% Check r boundary
if ( r < 0 ) set(handles.var_r,'String',0);
elseif ( r > slider_r_max ) set(handles.var_r,'String',slider_r_max);
end

% Display R/G/B channel of selected area
imshow(Film_Area(:,:,rgb_i), 'Parent', handles.axes_FilmArea);
hold on;
circleDraw(hObject, handles)
hold off;

% Construct Optical Density plot
plot_OD(hObject, handles)
guidata(hObject, handles);
