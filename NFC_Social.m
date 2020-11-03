% Description: 
% This graphic user interface provides the framework to manipulate up to 
% four NFC optogenetic devices, each containing a single illumination 
% channel (one probe with one LED), within the same experimental enclosure.
% Parameters such as frequency, duty cycle, or tonic vs burst operation 
% can be individually programmed.
%
% Hardware requirement: 
% This GUI interfaces with a FEIG reader model LRM2500-A using RS232 
% serial communication. It uses 38400 baud rate (refer to line 124 if this 
% value needs to be changed).
%
% Possible issues: 
% -This GUI was tested in MATLAB versions 2018a and 2019b. Possible software
%  incompatibility might arise if attempting to use in newer versions of MATLAB. 
% -This GUI was designed to minimized code crashes. Any further modification 
%  could result in code instability.
% -The software uses RS232 serial communication and a RS232/USB converter
%  might be needed in most modern computers, for which the proper driver 
%  needs to be installed first prior to using this software. 
%
% Disclaimer:
% This GUI was developed to satisfy the experimental needs. Thus, it is 
% not warranted that all functions contained in this program will meet 
% your requirements, neither the operation of the program will be 
% error-free. However, its structural layout and functional logic might
% serve to as the basis to create customized versions that will satisfy 
% specific applications.
%
% Author: Abraham Vazquez-Guardado
% Center for Bio-Integrated Electronics
% Northwestern Univeristy
% Fall 2020
%
% Last Update: Nov. 3rd 2020

function varargout = NFC_Social(varargin)
% NFC_Social MATLAB code for NFC_Social.fig
%      NFC_Social, by itself, creates a new NFC_Social or raises the existing
%      singleton*.
%
%      H = NFC_Social returns the handle to a new NFC_Social or the handle to
%      the existing singleton*.
%
%      NFC_Social('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NFC_Social.M with the given input arguments.
%
%      NFC_Social('Property','Value',...) creates a new NFC_Social or raises
%      the existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before NFC_Social_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to NFC_Social_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help NFC_Social

% Last Modified by GUIDE v2.5 03-Nov-2020 11:16:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @NFC_Social_OpeningFcn, ...
    'gui_OutputFcn',  @NFC_Social_OutputFcn, ...
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

% --- Executes just before NFC_Social is made visible.
function NFC_Social_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to NFC_Social (see VARARGIN)

% Choose default command line output for NFC_Social
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% pos = get(gcf,'Position');
% pos(1:2) = [-700 300];
% set(gcf,'Position',pos);
% axes(handles.pulses_fig);
% plot_pulses(100,50,'00');

initialize_gui(hObject, handles, false);

% UIWAIT makes NFC_Social wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = NFC_Social_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

% --------------------------------------------------------------------
function initialize_gui(fig_handle, handles, isreset)

% defile colors
% load colors;
handles.ONColor = [210 0 0]/255;%color.reddevil;
handles.OFFColor = 240*[1 1 1]/255;
ports = seriallist;
[~,b] = size(ports);
set(handles.serial_port,'String',ports);
set(handles.serial_port,'Value',b);

% Set up serial port
handles.serial.s = serial(' ','BaudRate',38400);
handles.serial.s.InputBufferSize = 128;
handles.serial.s.Timeout = 5;
handles.serial.s.Parity = 'even';
handles.serial.s.StopBits = 1;
handles.serial.s.DataBits = 8;
handles.serial.s.port = ports{b};

% Initializes some flags
handles.flags.receiving = 0;
handles.flags.serial_active = 0;

set(handles.D1,'BackgroundColor',handles.OFFColor);
set(handles.D2,'BackgroundColor',handles.OFFColor);

files = ls('*.txt');
[nf,~] = size(files);
file_list{1} = 'Select UDID file';
for i=1:nf
    file_list{i+1} = files(i,:);
end
% set(handles.opt_files,'String',{'Select UDID file','hello','hello2'});
set(handles.opt_files,'String',file_list);

set(handles.opt_files,      'Enable','Off');
set(handles.show_nicknames, 'Enable','Off');
set(handles.D1,             'Enable','Off');
set(handles.D2,             'Enable','Off');
set(handles.D3,             'Enable','Off');
set(handles.D4,             'Enable','Off');
set(handles.D1_2,           'Enable','Off');
set(handles.d1_sel,         'Enable','Off');
set(handles.d2_sel,         'Enable','Off');
set(handles.d3_sel,         'Enable','Off');
set(handles.d4_sel,         'Enable','Off');

set(handles.cmd_read_UDID,  'Enable','Off');
set(handles.cmd_read,       'Enable','Off');
set(handles.cmd_write,      'Enable','Off');
set(handles.cmd_set_rfpower,'Enable','Off');
set(handles.cmd_RF_restart, 'Enable','Off');

set(handles.cmd_UDID_load,  'Enable','Off');
set(handles.DC1,            'Enable','Off');
set(handles.T1,             'Enable','Off');

set(handles.T2,             'Enable','Off');
set(handles.DC2,            'Enable','Off');
set(handles.rf_power,       'Enable','Off');

set(handles.rf_power,       'String',4);
set(handles.T2,             'String','---');
set(handles.DC2,            'String','---');
set(handles.DC1,            'String','---');
set(handles.T1,             'String','---');

% Initializes NFC values
handles.NFC.mode = 0;           % Mode of operation
handles.NFC.ChON1 = 0; 
handles.NFC.ChON2 = 0; 
handles.NFC.ChON3 = 0; 
handles.NFC.ChON4 = 0;        
handles.NFC.ChON1_2 = 0;

handles.NFC.T1 = 500;        % Two bytes of data for the period
handles.NFC.DC1 = 50;
handles.NFC.T2 = 500;        % Two bytes of data for the period
handles.NFC.DC2 = 50;

handles.NFC.addressedmode = 1;  % Addressed mode of operation
handles.NFC.UDID = '';          % Unique device identifier for addressed mode
handles.NFC.address = 0;
handles.NFC.data = [0 0 0 0];
handles.NFC.nAttempts = 5;      % Number of attempts to read or write
handles.NFC.P = 4;
handles.NFC.error = 0;          % If there is an error in the comm
guidata(handles.figure1, handles);

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%                         Callback functions
function serial_connect_Callback(hObject, eventdata, handles)
disp(handles.serial.s.port)
if handles.flags.serial_active == 0
    if ~strcmp(handles.serial.s.port,' ') % Connect
        fclose(instrfind)
        fopen(handles.serial.s);
        handles.flags.serial_active = 1;
        
        set(handles.connected,      'Value',1);
        set(handles.cmd_read_UDID,  'Enable','On');
        set(handles.cmd_set_rfpower,'Enable','On');
        set(handles.opt_files,  'Enable',   'On');
%         set(handles.cmd_UDID_load,'Enable','On');
%         set(handles.cmd_write,      'Enable','On');
%         set(handles.cmd_read,       'Enable','On');
%         set(handles.D1,            'Enable','On');
%         set(handles.D2,            'Enable','On');
%         set(handles.d1,            'Enable','On');
%         set(handles.d2,            'Enable','On');
%         set(handles.T2,              'Enable','On');
%         set(handles.DC2,             'Enable','On');
        set(handles.serial_port,    'Enable','Off');
        set(handles.rf_power,       'Enable','On');
        set(handles.serial_connect, 'String','Disconnect');
        fprintf('Port open.\n');
        
        % Read power on the Feig reader
        P0 = dec2hex(handles.NFC.P,2);
        msg = '02000DFF8A020101000301';
        msg0 = [];
        for j0=1:(length(msg)/2)
            msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
        end
        crc = CRC16(msg0);
        handles.NFC.message = [msg0 crc];
        handles.NFC.waittime = 0.5;
        dataReceived = send_commands(handles);
        
        P0 = dataReceived(13);
        handles.NFC.P = P0;
        set(handles.rf_power,'String',num2str(P0));
        
    else
        disp('Select port first');
    end
else % Disconnect
    fclose(handles.serial.s)
    handles.flags.serial_active = 0;
    
    set(handles.connected,      'Value',0);
    set(handles.serial_port,    'Enable','On');
    set(handles.cmd_write,      'Enable','Off');
    set(handles.cmd_read,       'Enable','Off');
    set(handles.serial_connect, 'String','Connect');
    set(handles.cmd_read_UDID,  'Enable','Off');
    set(handles.D1,             'Enable','Off');
    set(handles.D2,             'Enable','Off');
    set(handles.D3,             'Enable','Off');
    set(handles.D4,             'Enable','Off');
    set(handles.D1_2,           'Enable','Off');
    set(handles.d1_sel,         'Enable','Off');
    set(handles.d2_sel,         'Enable','Off');
    set(handles.d3_sel,         'Enable','Off');
    set(handles.d4_sel,         'Enable','Off');
    set(handles.cmd_set_rfpower', 'Enable','Off');
    set(handles.T2,             'Enable','Off');
    set(handles.T1,             'Enable','Off');
    set(handles.DC2,            'Enable','Off');
    set(handles.DC1,            'Enable','Off');
    set(handles.rf_power,       'Enable','Off');

    set(handles.opt_files,      'Enable',   'Off');
    set(handles.cmd_UDID_load,  'Enable','Off');
    set(handles.txt_udid1,'String','xx-xx-xx-xx-xx-xx-xx-xx');
    set(handles.txt_udid2,'String','xx-xx-xx-xx-xx-xx-xx-xx');
    set(handles.txt_udid3,'String','xx-xx-xx-xx-xx-xx-xx-xx');
    set(handles.txt_udid4,'String','xx-xx-xx-xx-xx-xx-xx-xx');
    set(handles.T2,              'String','---');
    set(handles.DC2,             'String','---');
    set(handles.T1,              'String','---');
    set(handles.DC1,             'String','---'); 
    fprintf('Port closed.\n');
end
guidata(hObject,handles)

function cmd_write_Callback(hObject, eventdata, handles)
disp( ' ');
if get(handles.d1_sel,'Value') == 1
    index = 1;
elseif get(handles.d2_sel,'Value') == 1
    index = 2;
elseif get(handles.d3_sel,'Value') == 1
    index = 3;
elseif get(handles.d4_sel,'Value') == 1
    index = 4;
else
    index = 1;
    set(handles.d1_sel,'Value',1);
end
% Send the burst, T2 and DC2 at block 3 for CH2
str = [];
handles.NFC.UDID = handles.NFC.UDID_s{index};
for j0 = 1:8
    str = [str dec2hex(handles.NFC.UDID(j0),2) '-'];    % UDID in string form
end
str = str(1:(end-1));
temp = strfind(str,'-');
str(temp) = '';
msg = ['020018FFB02401' str];
T0 = dec2hex(handles.NFC.T2,4);
DC0 = dec2hex(round(handles.NFC.T2*handles.NFC.DC2/100),4);
msg = [msg '03' '0104' T0 DC0];
msg0 = [];
for j0=1:(length(msg)/2)
    msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
end
crc = CRC16(msg0);
handles.NFC.message = [msg0 crc];
handles.NFC.waittime = 0.15;
dataReceived = send_commands(handles);
if dataReceived == 0
    disp('No data saved to device')
end

% Send the blinking, T1 and DC1 at block 4 for CH2
T0 = dec2hex(handles.NFC.T1,4);
DC0 = dec2hex(round(handles.NFC.DC1),2);
msg = ['020018FFB02401' str];
msg = [msg '04' '0104' '00' T0 DC0];
msg0 = [];
for j0=1:(length(msg)/2)
    msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
end
crc = CRC16(msg0);
handles.NFC.message = [msg0 crc];
handles.NFC.waittime = 0.15;
dataReceived = send_commands(handles);
if dataReceived == 0
    disp('No data saved to device')
end

function cmd_read_Callback(hObject, eventdata, handles)
% Read memory  state
disp( ' ');
if get(handles.d1_sel,'Value') == 1
    index = 1;
elseif get(handles.d2_sel,'Value') == 1
    index = 2;
elseif get(handles.d3_sel,'Value') == 1
    index = 3;
elseif get(handles.d4_sel,'Value') == 1
    index = 4;
else
    index = 1;
    set(handles.d1_sel,'Value',1);
end

str = [];
handles.NFC.UDID = handles.NFC.UDID_s{index};
for j0 = 1:8
    str = [str dec2hex(handles.NFC.UDID(j0),2) '-'];    % UDID in string form
end
str = str(1:(end-1));
temp = strfind(str,'-');
str(temp) = ''; 
% Reads burst given by memory locations 3 (for the current CH2)
msg = ['020013FFB02301' str];
msg = [msg '03' '01'];
msg0 = [];
for j0=1:(length(msg)/2)
    msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
end
crc = CRC16(msg0);
handles.NFC.message = [msg0 crc];
handles.NFC.waittime = 0.15;
dataReceived = send_commands(handles);

if dataReceived(1) ~= 0
    handles.NFC.channelState = dataReceived(10:13);
    T = dataReceived(10)*256+dataReceived(11);
    DC = dataReceived(12)*256+dataReceived(13);
    DC = round(100*DC/T);
    handles.NFC.T2 = T;
    handles.NFC.DC2 = DC;
    set(handles.T2,'String',num2str(T));
    set(handles.DC2,'String',num2str(DC));
end

% Reads the blinking given by memory locations 4 (for the current CH2)
msg = ['020013FFB02301' str];
msg = [msg '04' '01'];
msg0 = [];
for j0=1:(length(msg)/2)
    msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
end
crc = CRC16(msg0);
handles.NFC.message = [msg0 crc];
handles.NFC.waittime = 0.15;
dataReceived = send_commands(handles);

if dataReceived(1) ~= 0
    handles.NFC.channelState = dataReceived(10:13);
    DC = dataReceived(13);
    T = round((dataReceived(11)*256+dataReceived(12)));
    handles.NFC.T1 = T;
    handles.NFC.DC1 = DC;
    set(handles.DC1,'String',num2str(DC));
    set(handles.T1,'String',num2str(1e-3*T));
end
message_stimulations(handles);
guidata(hObject, handles);

function cmd_read_UDID_Callback(hObject, eventdata, handles)
handles.NFC.waittime = 0.25;
[UDID,n] = get_inventory(handles);

if n==0
    disp('No devices found.');
else
    handles.NFC.addressed = 1;
    if n>0
        fname = 'UDID_list.txt';
        fid=fopen(fname,'w');
        fprintf(fid, ['Index\t UDID CODE\t\t nickname\n']);
        for i=1:n
            fprintf(fid, [num2str(i) '\t' UDID.str{i} '\t ID' num2str(i) '\n']);
            switch i
                case 1, set(handles.txt_udid1,'String',UDID.str{i});
                case 2, set(handles.txt_udid2,'String',UDID.str{i});
                case 3, set(handles.txt_udid3,'String',UDID.str{i});
                case 4, set(handles.txt_udid4,'String',UDID.str{i});
            end
        end
        fclose(fid);
        %     set(handles.txt_messages,'String',[num2str(n) ' devices were found inside the cage. ' ...
        %         'UDID list saved to ' fname '.']);
    end
    handles.NFC.UDID_n = n;                 % Number of devices
    handles.NFC.UDID_s = UDID.num;          % UDIDs in dec format
    handles.NFC.UDID_str = UDID.str;        % UDIDs in str format
    handles.NFC.UDID_nicknames = UDID.nicknames;
    set(handles.cmd_write,     'Enable','On');
    set(handles.cmd_read,      'Enable','On');
    
    set(handles.T2,            'Enable','On');
    set(handles.DC2,           'Enable','On');
    set(handles.DC1,           'Enable','On');
    set(handles.T1,            'Enable','On');
    set(handles.show_nicknames,'Enable','On');
    
    switch n
        case 1
            set(handles.D1,            'Enable','On');
            set(handles.d1_sel,        'Enable','On');
        case 2
            set(handles.D1,            'Enable','On');
            set(handles.d1_sel,        'Enable','On');
            set(handles.D2,            'Enable','On');
            set(handles.d2_sel,        'Enable','On');
        case 3
            set(handles.D1,            'Enable','On');
            set(handles.d1_sel,        'Enable','On');
            set(handles.D2,            'Enable','On');
            set(handles.d2_sel,        'Enable','On');
            set(handles.D3,            'Enable','On');
            set(handles.d3_sel,        'Enable','On');
        case 4
            set(handles.D1,            'Enable','On');
            set(handles.d1_sel,        'Enable','On');
            set(handles.D2,            'Enable','On');
            set(handles.d2_sel,        'Enable','On');
            set(handles.D3,            'Enable','On');
            set(handles.d3_sel,        'Enable','On');
            set(handles.D4,            'Enable','On');
            set(handles.d4_sel,        'Enable','On');
            
    end
    if n >= 2
        
        set(handles.D1_2,            'Enable','On');
    end
    if n>4
        
        set(handles.D1,            'Enable','On');
        set(handles.d1_sel,        'Enable','On');
        set(handles.D2,            'Enable','On');
        set(handles.d2_sel,        'Enable','On');
        set(handles.D3,            'Enable','On');
        set(handles.d3_sel,        'Enable','On');
        set(handles.D4,            'Enable','On');
        set(handles.d4_sel,        'Enable','On');
    end
end

guidata(hObject, handles);

function cmd_set_rfpower_Callback(hObject, eventdata, handles)
P0 = dec2hex(handles.NFC.P,2);
msg = ['02002CFF8B020101011E00030008' P0 '800000000000000000000000000000000000000000000000000000'];
msg0 = [];
for j0=1:(length(msg)/2)
    msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
end
crc = CRC16(msg0);
handles.NFC.message = [msg0 crc];
handles.NFC.waittime = 0.25;
dataReceived = send_commands(handles);

if dataReceived(6) == 0
    disp('Data received.');
    msg = '020007FF63';
    msg0 = [];
    for j0=1:(length(msg)/2)
        msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
    end
    crc = CRC16(msg0);
    handles.NFC.message = [msg0 crc];
    handles.NFC.waittime = 0.5;
    dataReceived = send_commands(handles);
else
end

function d1_sel_Callback(hObject, eventdata, handles)
set(handles.d2_sel,'Value',0);
set(handles.d3_sel,'Value',0);
set(handles.d4_sel,'Value',0);
guidata(hObject, handles);

function d2_sel_Callback(hObject, eventdata, handles)
set(handles.d1_sel,'Value',0);
set(handles.d3_sel,'Value',0);
set(handles.d4_sel,'Value',0);
guidata(hObject, handles);

function d3_sel_Callback(hObject, eventdata, handles)
set(handles.d1_sel,'Value',0);
set(handles.d2_sel,'Value',0);
set(handles.d4_sel,'Value',0);
guidata(hObject, handles);

function d4_sel_Callback(hObject, eventdata, handles)
set(handles.d1_sel,'Value',0);
set(handles.d2_sel,'Value',0);
set(handles.d3_sel,'Value',0);
guidata(hObject, handles);

function D1_Callback(hObject, eventdata, handles)

if handles.NFC.ChON1 == 0
    ONOFF = '02';
else
    ONOFF = '00';
end

str = [];
handles.NFC.UDID = handles.NFC.UDID_s{1};
for j0 = 1:8
    str = [str dec2hex(handles.NFC.UDID(j0),2) '-'];    % UDID in string form
end
str = str(1:(end-1));
temp = strfind(str,'-');
str(temp) = '';
msg = ['020018FFB02401' str];
msg = [msg '000104' '0001' ONOFF '00'];

msg0 = [];
for j0=1:(length(msg)/2)
    msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
end
crc = CRC16(msg0);
handles.NFC.message = [msg0 crc];
handles.NFC.waittime = 0.25;
dataReceived = send_commands(handles);

if dataReceived(1) ~= 0 
    if handles.NFC.ChON1 == 0
        handles.NFC.ChON1 = 1;
        set(handles.D1,'BackgroundColor',handles.ONColor);
    else
        handles.NFC.ChON1 = 0;
        set(handles.D1,'BackgroundColor',handles.OFFColor);
    end
end
guidata(hObject, handles);

function D2_Callback(hObject, eventdata, handles)

if handles.NFC.ChON2 == 0
    ONOFF = '02';
else
    ONOFF = '00';
end

str = [];
handles.NFC.UDID = handles.NFC.UDID_s{2};
for j0 = 1:8
    str = [str dec2hex(handles.NFC.UDID(j0),2) '-'];    % UDID in string form
end
str = str(1:(end-1));
temp = strfind(str,'-');
str(temp) = '';
msg = ['020018FFB02401' str];
msg = [msg '000104' '0001' ONOFF '00'];

msg0 = [];
for j0=1:(length(msg)/2)
    msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
end
crc = CRC16(msg0);
handles.NFC.message = [msg0 crc];
handles.NFC.waittime = 0.25;
dataReceived = send_commands(handles);

if dataReceived(1) ~= 0 
    if handles.NFC.ChON2 == 0
        handles.NFC.ChON2 = 1;
        set(handles.D2,'BackgroundColor',handles.ONColor);
    else
        handles.NFC.ChON2 = 0;
        set(handles.D2,'BackgroundColor',handles.OFFColor);
    end
end
guidata(hObject, handles);

function D3_Callback(hObject, eventdata, handles)

if handles.NFC.ChON3 == 0
    ONOFF = '02';
else
    ONOFF = '00';
end

str = [];
handles.NFC.UDID = handles.NFC.UDID_s{3};
for j0 = 1:8
    str = [str dec2hex(handles.NFC.UDID(j0),2) '-'];    % UDID in string form
end
str = str(1:(end-1));
temp = strfind(str,'-');
str(temp) = '';
msg = ['020018FFB02401' str];
msg = [msg '000104' '0001' ONOFF '00'];

msg0 = [];
for j0=1:(length(msg)/2)
    msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
end
crc = CRC16(msg0);
handles.NFC.message = [msg0 crc];
handles.NFC.waittime = 0.25;
dataReceived = send_commands(handles);

if dataReceived(1) ~= 0  
    if handles.NFC.ChON3 == 0
        handles.NFC.ChON3 = 1;
        set(handles.D3,'BackgroundColor',handles.ONColor);
    else
        handles.NFC.ChON3 = 0;
        set(handles.D3,'BackgroundColor',handles.OFFColor);
    end
end
guidata(hObject, handles);

function D4_Callback(hObject, eventdata, handles)

if handles.NFC.ChON4 == 0
    ONOFF = '02';
else
    ONOFF = '00';
end

str = [];
handles.NFC.UDID = handles.NFC.UDID_s{4};
for j0 = 1:8
    str = [str dec2hex(handles.NFC.UDID(j0),2) '-'];    % UDID in string form
end
str = str(1:(end-1));
temp = strfind(str,'-');
str(temp) = '';
msg = ['020018FFB02401' str];
msg = [msg '000104' '0001' ONOFF '00'];

msg0 = [];
for j0=1:(length(msg)/2)
    msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
end
crc = CRC16(msg0);
handles.NFC.message = [msg0 crc];
handles.NFC.waittime = 0.25;
dataReceived = send_commands(handles);

if dataReceived(1) ~= 0 
    if handles.NFC.ChON4 == 0
        handles.NFC.ChON4 = 1;
        set(handles.D4,'BackgroundColor',handles.ONColor);
    else
        handles.NFC.ChON4 = 0;
        set(handles.D4,'BackgroundColor',handles.OFFColor);
    end
end
guidata(hObject, handles);

function D1_2_Callback(hObject, eventdata, handles)
opt = 0; % one for addressed mode, zero for non addressed
if opt == 1
    if handles.NFC.ChON1_2 == 0
        ONOFF = '02';
    else
        ONOFF = '00';
    end
    % Prep for dev 1
    str = [];
    handles.NFC.UDID = handles.NFC.UDID_s{1};
    for j0 = 1:8
        str = [str dec2hex(handles.NFC.UDID(j0),2) '-'];    % UDID in string form
    end
    str = str(1:(end-1));
    temp = strfind(str,'-');
    str(temp) = '';
    msg = ['020018FFB02401' str];
    msg = [msg '000104' '0001' ONOFF '00'];

    msg0 = [];
    for j0=1:(length(msg)/2)
        msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
    end
    crc = CRC16(msg0);
    msg1 = [msg0 crc];

    % Prep for dev 2
    str = [];
    handles.NFC.UDID = handles.NFC.UDID_s{2};
    for j0 = 1:8
        str = [str dec2hex(handles.NFC.UDID(j0),2) '-'];    % UDID in string form
    end
    str = str(1:(end-1));
    temp = strfind(str,'-');
    str(temp) = '';
    msg = ['020018FFB02401' str];
    msg = [msg '000104' '0001' ONOFF '00'];

    msg0 = [];
    for j0=1:(length(msg)/2)
        msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
    end
    crc = CRC16(msg0);
    msg2 = [msg0 crc];

    handles.NFC.message = msg1;
    handles.NFC.waittime = 0.035;
    dataReceived1 = send_commands(handles);

    handles.NFC.message = msg2;
    handles.NFC.waittime = 0.035;
    dataReceived2 = send_commands(handles);


    if (dataReceived1(1) ~= 0) & (dataReceived2(1) ~= 0 )
        if handles.NFC.ChON1_2 == 0
            handles.NFC.ChON1_2 = 1;
            set(handles.D1_2,'BackgroundColor',handles.ONColor);
        else
            handles.NFC.ChON1_2 = 0;
            set(handles.D1_2,'BackgroundColor',handles.OFFColor);
        end
    end

else
    if handles.NFC.ChON1_2 == 0
        msg = '020010FFB0240000010400010200';
    else
        msg = '020010FFB0240000010400010000';
    end
    
    msg0 = [];
    for j0=1:(length(msg)/2)
        msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
    end
    crc = CRC16(msg0);
    msg = [msg0 crc];

    handles.NFC.message = msg;
    handles.NFC.waittime = 0.3;
    dataReceived = send_commands(handles);
    if (dataReceived(1) ~= 0)
        if handles.NFC.ChON1_2 == 0
            handles.NFC.ChON1_2 = 1;
            set(handles.D1_2,'BackgroundColor',handles.ONColor);
        else
            handles.NFC.ChON1_2 = 0;
            set(handles.D1_2,'BackgroundColor',handles.OFFColor);
        end
    end

end
guidata(hObject, handles);

% Parameters for the blinking
function T2_Callback(hObject, eventdata, handles)
temp = str2double(get(hObject,'String'));
handles.NFC.T2 = temp;
message_stimulations(handles);
guidata(hObject, handles);

function DC2_Callback(hObject, eventdata, handles)
temp = str2double(get(hObject,'String'));
if temp > 100
    beep;
    set(hObject,'String',100);
    handles.NFC.DC2 = 100;
else
    handles.NFC.DC2 = temp;
end
message_stimulations(handles);
guidata(hObject, handles);

% Parameters for the burst (stay as is)
function T1_Callback(hObject, eventdata, handles)
temp = str2double(get(hObject,'String'));
handles.NFC.T1 = temp*1000;
if temp*1000 > 65500
    handles.NFC.T1 = 65000;
    set(handles.T1,'String','65');
end
message_stimulations(handles);
guidata(hObject, handles);

function DC1_Callback(hObject, eventdata, handles)
temp = str2double(get(hObject,'String'));
if temp > 100
    beep;
    set(hObject,'String',100);
    handles.NFC.DC1 = 100;
else
    handles.NFC.DC1 = temp;
end
message_stimulations(handles);
guidata(hObject, handles);

function serial_port_Callback(hObject, eventdata, handles)
contents = cellstr(get(hObject,'String'));
handles.serial.s.port = contents{get(hObject,'Value')};
guidata(hObject, handles);

function UDID_devices_Callback(hObject, eventdata, handles)
temp = get(hObject,'Value');
handles.NFC.UDID = handles.NFC.UDID_s{temp};
guidata(hObject, handles);

function rf_power_Callback(hObject, eventdata, handles)
temp = str2double(get(hObject,'String'));
handles.NFC.P = temp;
guidata(hObject, handles);

function opt_files_Callback(hObject, eventdata, handles)
contents = cellstr(get(hObject,'String'));
handles.UDID_filelist = contents{get(hObject,'Value')};
if exist(handles.UDID_filelist) ~= 0
    set(handles.cmd_UDID_load,'Enable','On');
    guidata(hObject, handles);
end

function cmd_UDID_load_Callback(hObject, eventdata, handles)

fid = fopen(handles.UDID_filelist,'r');
temp = fgetl(fid);
for i=1:4
    if feof(fid), break; end
    temp = fgetl(fid);
    IDs(i) = temp(1);
    
    temp1 = temp(3:25);
    for j=1:8
        temp2(j) = hex2dec(temp1((j-1)*3+[1 2]));
    end
    UDID.num{i} = temp2;
    UDID.str{i} = temp1;
    UDID.nicknames{i} = temp(28:end);
    switch i
        case 1, set(handles.txt_udid1,'String',UDID.str{i});
        case 2, set(handles.txt_udid2,'String',UDID.str{i});
        case 3, set(handles.txt_udid3,'String',UDID.str{i});
        case 4, set(handles.txt_udid4,'String',UDID.str{i});
    end
end
n = i;
fclose(fid);

handles.NFC.UDID_n = n;                 % Number of devices
handles.NFC.UDID_s = UDID.num;          % UDIDs in dec format
handles.NFC.UDID_str = UDID.str;        % UDIDs in str format
handles.NFC.UDID_nicknames = UDID.nicknames;
set(handles.cmd_write,      'Enable','On');
set(handles.cmd_read,       'Enable','On');
set(handles.D1,            'Enable','On');
set(handles.D2,            'Enable','On');
set(handles.D3,            'Enable','On');
set(handles.D4,            'Enable','On');
set(handles.d1_sel,         'Enable','On');
set(handles.d2_sel,            'Enable','On');
set(handles.d3_sel,            'Enable','On');
set(handles.d4_sel,            'Enable','On');
set(handles.T2,              'Enable','On');
set(handles.DC2,             'Enable','On');
set(handles.DC1,      'Enable','On');
set(handles.show_nicknames, 'Enable','On');
guidata(hObject, handles);
  
function show_nicknames_Callback(hObject, eventdata, handles)
if get(hObject,'Value') == 1
    for i=1:handles.NFC.UDID_n
        switch i
            case 1, set(handles.txt_udid1,'String',handles.NFC.UDID_nicknames{i});
            case 2, set(handles.txt_udid2,'String',handles.NFC.UDID_nicknames{i});
            case 3, set(handles.txt_udid3,'String',handles.NFC.UDID_nicknames{i});
            case 4, set(handles.txt_udid4,'String',handles.NFC.UDID_nicknames{i});
        end
    end
else
    for i=1:handles.NFC.UDID_n
        switch i
            case 1, set(handles.txt_udid1,'String',handles.NFC.UDID_str{i});
            case 2, set(handles.txt_udid2,'String',handles.NFC.UDID_str{i});
            case 3, set(handles.txt_udid3,'String',handles.NFC.UDID_str{i});
            case 4, set(handles.txt_udid4,'String',handles.NFC.UDID_str{i});
        end
    end
end

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%                            My funtions
function data = send_commands(handles)
if handles.NFC.waittime == 0
    handles.NFC.waittime = 0.25;
end
flushinput(handles.serial.s);            % Cleans input buffer
fprintf('   |Sent>>  ');

for ia = 1:length(handles.NFC.message)
    fprintf('%s ',dec2hex(handles.NFC.message(ia),2));
end
fprintf('\n');

if handles.flags.serial_active == 1
    for nAttempts = 1:handles.NFC.nAttempts
        fwrite(handles.serial.s,handles.NFC.message);
        handles.flags.receiving = 1;
        pause(handles.NFC.waittime);
        nData = handles.serial.s.BytesAvailable;
        if nData > 0
            data = fread(handles.serial.s,nData)';
            fprintf('<<Received| ');
            for j0 = 1:(length(data))
                fprintf('%s ',dec2hex(data(j0),2));
            end
            switch dec2hex(data(6),2)
                case '00'
%                     handles.NFC.error = 0;
                    fprintf('\n');
                    return
                case '01'
%                     handles.NFC.error = 1;
                    data = 0;
                    fprintf('\nReader: No transponder in the Reader Field');
                    fprintf('| No response, attempt %d of %d',nAttempts, handles.NFC.nAttempts);
                case '84'
                    if data(7) == 0
%                         handles.NFC.error = 1;
                        data = 0;
                        fprintf('\nReader: RF-Warning\n');
                        return
                    end
            end
        end
        fprintf('\n');
    end
end

function data = CRC16(msg)
crc_poly = uint16(hex2dec('8408'));
crc = uint16(hex2dec('FFFF'));
for i=1:length(msg)
    crc = bitxor(crc,msg(i));
    for j=1:8
        if bitand(crc,1)
            crc = bitxor(bitshift(crc,-1),crc_poly);
        else
            crc = bitshift(crc,-1);
        end
    end
end
data = dec2hex(crc,4);
data = [hex2dec(data(3:4)) hex2dec(data(1:2))];

function [UDID,n] = get_inventory(handles)
msg = '020009FFB00100';
msg0 = [];
for j0=1:(length(msg)/2)
    msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
end
crc = CRC16(msg0);
handles.NFC.message = [msg0 crc];
data = send_commands(handles);
if data(1) == 0
    n = 0;
    UDID = [];
    str0 = [];
    return;
end

if data(6) == 0
    n = data(7);                                % Number of devices found
    UDID = [];
    str0 = [];
    for i0 = 1:n
        
        UDID.num{i0} = data(i0*10-1+(1:8));     % Get the UDID value, dec
        str = [];
        for j0 = 1:8
            str = [str dec2hex(UDID.num{i0}(j0),2) '-'];    % UDID in string form
        end
        UDID.str{i0} = str(1:(end-1));
        
    end
else
    n = 0;
    UDID = [];
    str0 = [];
end

function txt_messages_Callback(hObject, eventdata, handles)

function message_stimulations(handles)
% Do some calculations here
T1 = handles.NFC.T1;
T2 = handles.NFC.T2;
DC1 = handles.NFC.DC1;
DC2 = handles.NFC.DC2;

if DC2 < 100
    str = sprintf('Low frequency: %2.1f Hz @ %d %% | ',1e3/T2,DC2);
else
    str = sprintf('Low frequency: OFF | ');
%     str0 = 'Regular stimulation using High Freq.'
end
if DC1 < 100
    str = [str sprintf('High frequency: %d Hz @ %d %%\n',1e6/T1,DC1)];
else
    str = [str sprintf('High frequency: OFF\n')];
%     str0 = 'Regular stimulation using Low Freq timer.'
end

if (DC1 < 100) & (DC2 < 100)
    TOnBurst = T2 * DC2 / 100;
    TOnBlink = 1e-3 * T1 * DC1 / 100;
    nPulses = floor(TOnBurst / (1e-3*T1));
    str0 = sprintf('Running on burst mode: %d pulses every %2.2f s',nPulses, T2/1000);
else
    str0 = 'Regular stimulation using Low Freq timer.';
end

str = [str str0];
set(handles.txt_messages,'String',str);


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%                     Functions used by the app
function DC2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function T2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function rf_power_CreateFcn(hObject, eventdata, handles)
function serial_port_CreateFcn(hObject, eventdata, handles)
% hObject    handle to serial_port (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function txt_messages_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_messages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function connected_Callback(hObject, eventdata, handles)
function cmd_RF_restart_Callback(hObject, eventdata, handles)
function DC1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function opt_files_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function T1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
