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

% Draw 3 circles: of selected radius, and +/- tolerance
function circleDraw(hObject, handles)
% Acquire vars
global vertex;
r = str2double(get(handles.var_r, 'String'));
rTol = str2double(get(handles.var_rTol, 'String'));
dpi = str2double(get(handles.var_dpi, 'String'));
r_px = r*dpi/25.4; r_pxTol = rTol*dpi/25400; % get r +- rTol in px

% Create circles with... rectangle(), because MATLAB
rectangle('Position', [vertex(2)-r_px vertex(1)-r_px 2*r_px 2*r_px], ...
          'Curvature', [1 1], 'Parent', handles.axes_FilmArea)
rectangle('Position', [vertex(2)-(r_px+r_pxTol) vertex(1)-(r_px+r_pxTol) 2*(r_px+r_pxTol) 2*(r_px+r_pxTol)], ...
          'Curvature', [1 1], 'Parent', handles.axes_FilmArea)
rectangle('Position', [vertex(2)-(r_px-r_pxTol) vertex(1)-(r_px-r_pxTol) 2*(r_px-r_pxTol) 2*(r_px-r_pxTol)], ...
          'Curvature', [1 1], 'Parent', handles.axes_FilmArea)

% Update vertex text
vertex_str = strcat('(', num2str(vertex(2,1)), ',', num2str(vertex(1,1)), ')');
set(handles.text_vertex, 'String', vertex_str);


function plot_OD(hObject, handles)
% Acquire vars
global Film_Area vertex I_r;
r = str2double(get(handles.var_r,'String'));
rTol = str2double(get(handles.var_rTol,'String'))/1000;
dpi = str2double(get(handles.var_dpi,'String'));
r_px = r*dpi/25.4; r_pxTol = rTol*dpi/25400; % get r +- rTol in px
rgb = get(handles.text_rgb, 'String');
if ( strcmp(rgb,'Red') ) rgb_i=1; elseif ( strcmp(rgb, 'Green') ) rgb_i=2; else rgb_i=3; end
dtheta = 1;

% Angular range: circle for source...
if get(handles.source_point, 'Value')
    theta=0:dtheta:360;
else % ...user defined otherwise
    angleFrom = str2double(get(handles.var_angleFrom, 'String'));
    angleTo = str2double(get(handles.var_angleTo, 'String'));
    theta=angleFrom:dtheta:angleTo;
end

% Create data point for each angle
I_numpoints = max(theta) - min(theta) + 1; % angular iterations including the zeroth
I_avg = zeros(I_numpoints); I_r = zeros(I_numpoints);

% 0.001 um increments from r +/- rTol
rInc = 0.001/1000; rSteps = 2*rTol/rInc;

% Loop through whole angle;
for i_theta=1:1:I_numpoints;
    % Get angle in radians
    theta_rad = theta(i_theta)*pi/180;
    for rStep_i = 0:rSteps
        try
            % Get r_i in px
            r_pxi = (r - rTol + rStep_i*rInc)*dpi/25.4;
            
            % Find closest pixel, assume value
            I_y = round(vertex(1, rgb_i) - r_pxi*sin(theta_rad));
            I_x = round(vertex(2, rgb_i) + r_pxi*cos(theta_rad));
            I_avg(i_theta) = double(I_avg(i_theta) + Film_Area(I_y, I_x, rgb_i)/(rSteps+1));
        catch
            continue;
        end
    end
    I_y = round(vertex(1, rgb_i) - r_px*sin(theta_rad));
    I_x = round(vertex(2, rgb_i) + r_px*cos(theta_rad));
    I_r(i_theta) = Film_Area(I_y, I_x, rgb_i);
end
% Plot I(theta) for r=radius (blue) and r=radius +/- tolerance (red)
plot(min(theta):max(theta), I_r, 'b-', 'Parent', handles.axes_OD); hold on;
plot(min(theta):max(theta), I_avg, 'r-', 'Parent', handles.axes_OD); hold off;
axis(handles.axes_OD, [min(theta) max(theta) min(min(I_r(:,1),I_avg(:,1))) max(max(I_r(:,1),I_avg(:,1)))]);
xlabel(handles.axes_OD, 'Degrees')
ylabel(handles.axes_OD, 'Grayscale (abs)')



% --- Executes just before gfrgb_gui is made visible.
function gfrgb_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% Acquire vars
global Film_Area;

% Precise tolerance slider step (0.01 to 1 in steps of 0.01)
sliderStep = [0.1 0.1]/(10 - 0.1);
set(handles.slider_rTol, 'SliderStep', sliderStep);

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


% --- Executes during object creation, after setting all properties
function var_r_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties
function slider_r_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties
function var_rTol_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties
function slider_rTol_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties
function var_dpi_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties
function slider_dpi_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties
function var_angleTo_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in toggle_red.
function toggle_red_Callback(hObject, eventdata, handles)
if ( get(hObject, 'Value') == 1 )
    % Acquire vars
    global Film_Area vertex;

    % Change button values
    set(handles.toggle_green, 'Value', 0);
    set(handles.toggle_blue, 'Value', 0);
    set(handles.text_rgb, 'String', 'Red');
    vertex_str = strcat('(', num2str(vertex(2,3)), ',', num2str(vertex(1,3)), ')');
    set(handles.text_vertex, 'String', vertex_str);
    
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
    % Acquire vars
    global Film_Area vertex;

    % Change button values
    set(handles.toggle_red, 'Value', 0);
    set(handles.toggle_blue, 'Value', 0);
    set(handles.text_rgb, 'String', 'Green');
    vertex_str = strcat('(', num2str(vertex(2,3)), ',', num2str(vertex(1,3)), ')');
    set(handles.text_vertex, 'String', vertex_str);
    
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
    % Acquire vars
    global Film_Area vertex;

    % Change button values
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
% Acquire vars
global Film_Area
slider_r = get(hObject,'Value');
rgb = get(handles.text_rgb, 'String');
if ( strcmp(rgb,'Red') ) rgb_i=1; elseif ( strcmp(rgb, 'Green') ) rgb_i=2; else rgb_i=3; end
set(handles.var_r,'String', slider_r);

% Display R/G/B channel of selected area
imshow(Film_Area(:,:,rgb_i), 'Parent', handles.axes_FilmArea);
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
% Acquire vars
global Film_Area
slider_rTol = get(hObject,'Value');
rgb = get(handles.text_rgb, 'String');
if ( strcmp(rgb,'Red') ) rgb_i=1; elseif ( strcmp(rgb, 'Green') ) rgb_i=2; else rgb_i=3; end
set(handles.var_rTol, 'String', slider_rTol);

% Display R/G/B channel of selected area
imshow(Film_Area(:,:,rgb_i), 'Parent', handles.axes_FilmArea);
hold on;
circleDraw(hObject, handles)
hold off;
guidata(hObject, handles);


% --- Executes on angleFrom input
function var_angleFrom_Callback(hObject, eventdata, handles)
% Acquire vars
angleFrom = str2double(get(hObject,'String'));

% Ensure integer angle selection
if ( angleFrom ~= floor(angleFrom) )
    set(hObject, 'String', floor(angleFrom));
end


% --- Executes on angleTo input
function var_angleTo_Callback(hObject, eventdata, handles)
% Acquire vars
angleTo = str2double(get(hObject,'String'));

% Ensure integer angle selection
if ( angleTo ~= floor(angleTo) )
    set(hObject, 'String', floor(angleFrom));
end


% --- Executes on slider_dpi movement
function slider_dpi_Callback(hObject, eventdata, handles)
% dpi++
slider_dpi = get(hObject,'Value');
set(handles.var_dpi,'String', slider_dpi);
guidata(hObject, handles);


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
% Angles as well, if selected
angleFrom=0; angleTo=360;
if ( get(handles.source_seed, 'Value') )
    angleFrom = str2num(get(handles.var_angleFrom, 'String'));
    angleTo = str2num(get(handles.var_angleTo, 'String'));
end

% Check for numeric input
if ( isnan(r) )
    set(handles.var_r,'String', 0);
    errordlg('r must be a number', 'Error');
end
if ( isnan(rTol) )
    set(handles.var_rTol,'String', 1);
    errordlg('Tolerance must be a number', 'Error');
end
if ( isnan(dpi) )
    set(handles.var_dpi,'String', 72);
    errordlg('dpi must be a number', 'Error');
end
if ( isnan(angleFrom) )
    set(handles.var_dpi,'String', 0);
    errordlg('Initial angle must be a number', 'Error');
end
if ( isnan(angleTo) )
    set(handles.var_dpi,'String', 360);
    errordlg('Final angle must be a number', 'Error');
end

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


% --- Executes on button press in button_contour
function button_contour_Callback(hObject, eventdata, handles)
% Acquire vars
global Film_Area;
rgb = get(handles.text_rgb, 'String');
if ( strcmp(rgb,'Red') ) rgb_i=1; elseif ( strcmp(rgb, 'Green') ) rgb_i=2; else rgb_i=3; end

% Plot contour map of Film_Area in new window
ContourFig = figure('Name', 'contourPlot'); contourPlot = gca;
contour(Film_Area(:, :, rgb_i));
xlabel(contourPlot, 'x (relative to selection)')
ylabel(contourPlot, 'y (relative to selection)')
set(contourPlot, 'YDir', 'rev')


% --- Executes on button press in button_crit.
function button_crit_Callback(hObject, eventdata, handles)
%Acquire vars
global Film_Area I_r;
angleFrom = str2num(get(handles.angleFrom, 'String'));
angleTo = str2num(get(handles.angleFromTo, 'String'));

% Find critical angle of bias
[I_peak, theta_c] = max(I_r);

% Create plot of I(r) for theta=theta_c


% --- Executes during object creation, after setting all properties.
function var_angleFrom_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in source_buttons.
function source_buttons_SelectionChangeFcn(hObject, eventdata, handles)
source_select = get(eventdata.NewValue, 'Tag');
if ( strcmp(source_select, 'source_seed') )
    % Show advanced options for OD anglular analysis
    set(handles.text_arc, 'Enable', 'on');
    set(handles.text_dash, 'Enable', 'on');
    set(handles.var_angleFrom, 'Enable', 'on');
    set(handles.var_angleTo, 'Enable', 'on');
    set(handles.button_crit, 'Enable', 'on');
    guidata(hObject, handles);
else
    % Hide advanced options for OD anglular analysis
    set(handles.text_arc, 'Enable', 'off');
    set(handles.text_dash, 'Enable', 'off');
    set(handles.var_angleFrom, 'Enable', 'off');
    set(handles.var_angleTo, 'Enable', 'off');
    set(handles.button_crit, 'Enable', 'off');
    guidata(hObject, handles);
end