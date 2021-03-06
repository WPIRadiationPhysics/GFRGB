%% INITIALIZATION
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


%% AUXILIARY FUNCTIONS
% Draw 3 circles: of selected radius, and +/- tolerance
function circleDraw(hObject, handles)
% Acquire global and GUI variables
global vertex dpi Film_Area;
r = str2double(get(handles.var_r, 'String'));
rTol = str2double(get(handles.var_rTol, 'String'));
r_px = r*dpi/25.4; r_pxTol = rTol*dpi/25400; % get r +- rTol in px
rgb = get(handles.text_rgb, 'String');
if ( strcmp(rgb,'Red') ) rgb_i=1; elseif ( strcmp(rgb, 'Green') ) rgb_i=2; else rgb_i=3; end

% Create circles with... rectangle(), because MATLAB
rectangle('Position', [vertex(2,1)-r_px vertex(1,1)-r_px 2*r_px 2*r_px], ...
          'Curvature', [1 1], 'Parent', handles.axes_FilmArea)
rectangle('Position', [vertex(2,1)-(r_px+r_pxTol) vertex(1,1)-(r_px+r_pxTol) 2*(r_px+r_pxTol) 2*(r_px+r_pxTol)], ...
          'Curvature', [1 1], 'Parent', handles.axes_FilmArea)
rectangle('Position', [vertex(2,1)-(r_px-r_pxTol) vertex(1,1)-(r_px-r_pxTol) 2*(r_px-r_pxTol) 2*(r_px-r_pxTol)], ...
          'Curvature', [1 1], 'Parent', handles.axes_FilmArea)
rectangle('Position', [vertex(2,1)-0.5 vertex(1,1)-0.5 1 1], ...
          'Curvature', [1 1], 'Parent', handles.axes_FilmArea)

% Find critical angle of bias
% [I_peak, theta_c] = max(I_r);
% 
% For each degree, get total value of radial distribution
theta_c = 0; I_px = r*dpi/25.4;
Ir_min = 0;
for theta_deg=1:360
    % Radians
    theta_i = theta_deg*pi/180;
    
    % Loop through weighted angular analyses
    for i=1:I_px
        if (vertex(2,rgb_i)-i*sin(theta_i) > 0 && vertex(2,rgb_i)-i*sin(theta_i) < length(Film_Area(:,1,1)))
            if (vertex(1,rgb_i)+i*cos(theta_i) > 0 && vertex(1,rgb_i)+i*cos(theta_i) < length(Film_Area(1,:,1)))
                Ir_weighted(i) = Film_Area(floor(vertex(2,rgb_i)-i*sin(theta_i)), floor(vertex(1,rgb_i)+i*cos(theta_i)), rgb_i);
            else
                Ir_weighted(i) = 65536;
            end
        else
          Ir_weighted(i) = 65536;
        end
        % /((i*25.4/dpi)^2);
    end
    
    % Check for more optimized angle by totally lower grayscale across radius
    if ( Ir_min == 0 )
        Ir_min = sum(Ir_weighted);
    end
    if ( sum(Ir_weighted) <= Ir_min )
        Ir_min = sum(Ir_weighted);
        theta_c = theta_i;
    end
end

% Draw line from vertex to radial edge
radialLine = line([vertex(2,rgb_i) vertex(2,rgb_i) + r_px*cos(theta_c)], [vertex(1,rgb_i) vertex(1,rgb_i)-r_px*sin(theta_c)]);
set(radialLine, 'Parent', handles.axes_FilmArea);
      
% Update vertex text
vertex_str = strcat('(', num2str(vertex(2,1)), ',', num2str(vertex(1,1)), ')');
set(handles.text_vertex, 'String', vertex_str);


function plot_OD(hObject, handles)
% Acquire vars
global Film_Area vertex I_r I_avg dpi;
r = str2double(get(handles.var_r,'String'));
rTol = str2double(get(handles.var_rTol,'String'))/1000;
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
for i_theta=1:1:I_numpoints
    % Get angle in radians
    theta_rad = theta(i_theta)*pi/180;
    for rStep_i = 0:rSteps
        try
            % Get r_i in px
            r_pxi = (r - rTol + rStep_i*rInc)*dpi/25.4;
            
            % Find closest pixel, assume value
            if (round(vertex(2, rgb_i) + r_pxi*cos(theta_rad)) > 0 && round(vertex(2, rgb_i) + r_pxi*cos(theta_rad)) < length(Film_Area(:,1,1))) {
                if (round(vertex(1, rgb_i) - r_pxi*sin(theta_rad)) > 0 && round(vertex(1, rgb_i) - r_pxi*sin(theta_rad)) < length(Film_Area(1,:,1))) {
                    I_y = round(vertex(1, rgb_i) - r_pxi*sin(theta_rad));
                    I_x = round(vertex(2, rgb_i) + r_pxi*cos(theta_rad));
                }
            }
            I_avg(i_theta) = double(I_avg(i_theta) + Film_Area(I_y, I_x, rgb_i)/(rSteps+1));
        catch
            continue;
        end
    end
    if (round(vertex(2, rgb_i) + r_pxi*cos(theta_rad)) > 0 && round(vertex(2, rgb_i) + r_pxi*cos(theta_rad)) < length(Film_Area(:,1,1))) {
        if (round(vertex(1, rgb_i) - r_pxi*sin(theta_rad)) > 0 && round(vertex(1, rgb_i) - r_pxi*sin(theta_rad)) < length(Film_Area(1,:,1))) {
            I_y = round(vertex(1, rgb_i) - r_px*sin(theta_rad));
            I_x = round(vertex(2, rgb_i) + r_px*cos(theta_rad));
            I_r(i_theta) = Film_Area(I_y, I_x, rgb_i);
        }
    }
end
% Plot I(theta) for r=radius (blue) and r=radius +/- tolerance (red)
plot(min(theta):max(theta), I_r, 'b-', 'Parent', handles.axes_OD); hold on;
plot(min(theta):max(theta), I_avg, 'r-', 'Parent', handles.axes_OD); hold off;
axis(handles.axes_OD, [min(theta) max(theta) min(min(I_r(:,1),I_avg(:,1))) max(max(I_r(:,1),I_avg(:,1)))]);
xlabel(handles.axes_OD, 'Degrees')
ylabel(handles.axes_OD, 'Grayscale (abs)')


%% GUI FUNCTIONS
% --- Executes just before gfrgb_gui is made visible.
function gfrgb_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% Acquire vars
global Film_Area vertex;

% % Vertex xy adjust slider step (0 to 1 in steps of 0.01)
[Film_yMax, Film_xMax] = size(Film_Area(:, :, 1));
sliderStepY = [1 1]/(Film_yMax - 0);
set(handles.slider_FilmVertexY, 'SliderStep', sliderStepY);
sliderStepX = [1 1]/(Film_xMax - 0);
set(handles.slider_FilmVertexX, 'SliderStep', sliderStepX);

% Set slider max and vertex values
set(handles.slider_FilmVertexY, 'max', Film_yMax);
set(handles.slider_FilmVertexX, 'max', Film_xMax);
set(handles.slider_FilmVertexY, 'value', Film_yMax - vertex(1,1));
set(handles.slider_FilmVertexX, 'value', vertex(2,1));

% Precise tolerance slider step (0.1 to 10 in steps of 0.1)
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


%% ITEMIZED CALLBACKS
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
function var_angleTo_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function var_angleFrom_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function slider_FilmVertexY_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function slider_FilmVertexX_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
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
    vertex_str = strcat('(', num2str(vertex(2,3)), ', ', num2str(vertex(1,3)), ')');
    set(handles.text_vertex, 'String', vertex_str);
    
    % Display Blue channel of selected area
    imshow(Film_Area(:,:,3), 'Parent', handles.axes_FilmArea);
    hold on;
    circleDraw(hObject, handles)
    hold off;
end
guidata(hObject, handles);

% --- Executes on slider movement.
function slider_FilmVertexY_Callback(hObject, eventdata, handles)
% Acquire vars
global Film_Area vertex;
rgb = get(handles.text_rgb, 'String');
if ( strcmp(rgb,'Red') ) rgb_i=1; elseif ( strcmp(rgb, 'Green') ) rgb_i=2; else rgb_i=3; end

% Get value from slider and change vertex
[Film_yMax Film_xMax] = size(Film_Area(:, :, 1));
sliderY = get(hObject,'Value');
if ( sliderY <= Film_yMax && sliderY >= 0 ); vertex(1, rgb_i) = Film_yMax - sliderY; end

% Display R/G/B channel of selected area
imshow(Film_Area(:,:,rgb_i), 'Parent', handles.axes_FilmArea);
hold on;
circleDraw(hObject, handles)
hold off;
guidata(hObject, handles);

% --- Executes on slider movement.
function slider_FilmVertexX_Callback(hObject, eventdata, handles)
% Acquire vars
global Film_Area vertex;
rgb = get(handles.text_rgb, 'String');
if ( strcmp(rgb,'Red') ) rgb_i=1; elseif ( strcmp(rgb, 'Green') ) rgb_i=2; else rgb_i=3; end

% Get value from slider and change vertex
[Film_yMax Film_xMax] = size(Film_Area(:, :, 1));
sliderX = get(hObject,'Value');
if ( sliderX <= Film_xMax && sliderX >= 0 ); vertex(2, rgb_i) = sliderX; end

% Display R/G/B channel of selected area
imshow(Film_Area(:,:,rgb_i), 'Parent', handles.axes_FilmArea);
hold on;
circleDraw(hObject, handles)
hold off;
guidata(hObject, handles);

% --- Executes on slider_r movement
function slider_r_Callback(hObject, eventdata, handles)
% Acquire vars
global Film_Area;
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
slider_rTol = sprintf('%0.1f', get(hObject,'Value'));
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


% --- Executes on button press in button_recalculate.
function button_recalculate_Callback(hObject, eventdata, handles)
global Film_Area dpi
% Acquire state variables
slider_r_max = get(handles.slider_r, 'Max');
r = str2double(get(handles.var_r,'String'));
rTol = str2double(get(handles.var_rTol,'String'));
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
if ( isnan(angleFrom) )
    set(handles.var_angleFrom,'String', 0);
    errordlg('Initial angle must be a number', 'Error');
end
if ( isnan(angleTo) )
    set(handles.var_angleTo,'String', 360);
    errordlg('Final angle must be a number', 'Error');
end

% Check r boundary
if ( r < 0 ) set(handles.var_r,'String',0);
elseif ( r > slider_r_max ) set(handles.var_r,'String',slider_r_max);
end

% Display R/G/B channel of selected area
imshow(Film_Area(:,:,rgb_i), 'Parent', handles.axes_FilmArea);
hold on;
circleDraw(hObject, handles);
hold off;

% Construct Optical Density plot
plot_OD(hObject, handles);
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
title(contourPlot, 'Contour map of exposure')
set(contourPlot, 'YDir', 'rev')


% --- Executes on button press in button_crit.
function button_crit_Callback(hObject, eventdata, handles)
%Acquire vars
global Film_Area vertex dpi;
r = str2double(get(handles.var_r,'String'));
rgb = get(handles.text_rgb, 'String');
if ( strcmp(rgb,'Red') ) rgb_i=1; elseif ( strcmp(rgb, 'Green') ) rgb_i=2; else rgb_i=3; end
angleFrom = str2num(get(handles.var_angleFrom, 'String'));
angleTo = str2num(get(handles.var_angleTo, 'String'));

% Find critical angle of bias
% [I_peak, theta_c] = max(I_r);
% 
% For each degree, get total value of radial distribution w/ 1/r^2 weight
theta_c = 0;
Ir_min = 65536*I_px;
for theta_deg=1:360
    % Radians
    theta_i = theta_deg*pi/180;
    
    % Loop through weighted angular analyses
    for i=1:I_px
        Ir_weighted(i) = Film_Area( round(vertex(2,rgb_i)-i*sin(theta_c)), round(vertex(1,rgb_i)+i*cos(theta_c)), rgb_i)/((i*25.4/dpi)^2);
    end
    
    % Check for more optimized angle by totally lower grayscale across radius
    if ( sum(Ir_weighted) <= Ir_min )
        theta_c = theta_i;
    end
end

% Acquire dataset of intensity
for i=0:I_px
    I_theta(i+1) = Film_Area( round(vertex(2,rgb_i)-i*sin(theta_c)), round(vertex(1,rgb_i)+i*cos(theta_c)), rgb_i);
end

% Acquire dataset of intensity
I_px = r*dpi/25.4;
for i=0:I_px
    I_theta(i+1) = Film_Area(vertex(2,rgb_i)-i*sin(theta_c), vertex(1,rgb_i)+i*cos(theta_c), rgb_i);
end

% Create plot of I(r) for theta=theta_c
IrFig = figure('Name', 'seedIntensityPlot'); seedIntensityPlot = gca;
plot(I_theta)
xlabel(seedIntensityPlot, 'r (px)')
ylabel(seedIntensityPlot, 'Grayscale (abs)')
title(seedIntensityPlot, 'Intensity perpendicular to tilt')


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


% --- Executes on button press in button_print.
function button_print_Callback(hObject, eventdata, handles)
% Acquire vars
global vertex Film_Area I_r I_avg;
r = str2double(get(handles.var_r, 'String'));
rTol = str2double(get(handles.var_rTol, 'String'));
rgb = get(handles.text_rgb, 'String');
if ( strcmp(rgb, 'Red') ) rgb_i=1; elseif ( strcmp(rgb, 'Green') ) rgb_i=2; else rgb_i=3; end
theta=0:1:360;

% Create data directory: get date and time
var_now = clock;
data_dir_string = strcat('data_', ...
                         num2str(var_now(1)), '-', num2str(var_now(3)), '-', ...
                         num2str(var_now(2)), '_', num2str(var_now(4)), '-', ...
                         num2str(var_now(5)), '-', num2str(floor(var_now(6))));
mkdir(data_dir_string);

% Output vars to text file in data dir
datafile = strcat(data_dir_string, '/vars.txt');
datafileID = fopen(datafile, 'wt');
datafile_vars = strcat('Vertex: ', num2str(Film_Area(vertex(2, rgb_i), vertex(1, rgb_i), rgb_i)), ' at (', num2str(vertex(2, rgb_i)), ', ', num2str(vertex(1, rgb_i)), ')\n');
fprintf(datafileID, '%s Channel\n', rgb);
fprintf(datafileID, datafile_vars);
fprintf(datafileID,'Radius: %.2f +/- %.2f mm\n', r, rTol);
fclose(datafileID);

% Save I_r and I_avg as own var files
datafile = strcat(data_dir_string, '/I_r.txt');
datafileID = fopen(datafile, 'wt');
fprintf(datafileID,'# theta [deg]  I_r\n');
for i=1:361
  fprintf(datafileID,'%d  %d\n', i-1, I_r(i));
end
fclose(datafileID);

datafile = strcat(data_dir_string, '/I_avg.txt');
datafileID = fopen(datafile, 'wt');
fprintf(datafileID,'# theta [deg]  I_avg\n');
for i=1:361
  fprintf(datafileID,'%d  %d\n', i-1, I_avg(i));
end
fclose(datafileID);

% Output OD fig in data dir
datafile = strcat(data_dir_string, '/OD_theta.fig');
fh = figure('Name', 'OD_Plot'); OD_Plot = gca;
% opos = get(handles.axes_OD, 'outerposition');
% set(handles.axes_OD, 'outerposition', [0 0 1 1]);
% h_OD = findobj(gcf, 'Tag', 'axes_OD');
% copyobj(h_OD, fh);
plot(min(theta):max(theta), I_r, 'b-', 'Parent', OD_Plot); hold on;
plot(min(theta):max(theta), I_avg, 'r-', 'Parent', OD_Plot); hold off;
axis(OD_Plot, [min(theta) max(theta) min(min(I_r(:,1), I_avg(:,1))) max(max(I_r(:,1), I_avg(:,1)))]);
xlabel(OD_Plot, 'Degrees')
ylabel(OD_Plot, 'Grayscale (abs)')
saveas(fh, datafile, 'fig');
% set(handles.axes_OD, 'outerposition', opos);
close(fh);

% Reconstruct contour plot and save
ContourFig = figure('Name', 'contourPlot'); contourPlot = gca;
contour(Film_Area(:, :, rgb_i));
xlabel(contourPlot, 'x (relative to selection)')
ylabel(contourPlot, 'y (relative to selection)')
title(contourPlot, 'Contour map of exposure')
set(contourPlot, 'YDir', 'rev')
datafile = strcat(data_dir_string, '/Contour.fig');
saveas(ContourFig, datafile, 'fig');
close(ContourFig);
