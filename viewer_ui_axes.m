
[ecg, bp, spO2] = read_data();
viewer(ecg, bp, spO2)

% extract data path from config file and read signals
function [ecg, bp, spO2] = read_data()
    
    % Write path to signal files into config.txt
    config_file = fullfile(pwd,"config2.txt");
    keys = ["path","ecg", "bp", "spO2"];
    values = ["#PATH=", "#ECG=", "#BP=", "#SpO2="];
    config_label = dictionary(keys, values);
    
    ecg = struct();
    bp = struct();
    spO2 = struct();
    
    if isfile(config_file)
        lines = readlines(config_file);
        data_path = findInConfig(lines, config_label("path"), pwd, false); %find path

        ecg.file_path = findInConfig(lines, config_label("ecg"), fullfile(data_path, "dataECG_cleaned.csv"), true);
        bp.file_path = findInConfig(lines, config_label("bp"), fullfile(data_path, "dataBP_cleaned.csv"), true);
        spO2.file_path = findInConfig(lines, config_label("spO2"), fullfile(data_path, "dataspO2_cleaned.csv"), true);
    end
    if ~isfile(config_file) || isempty(data_path)
        disp('Select ECG file')
        [file,data_path] = uigetfile;
        ecg.file_path = fullfile(data_path, file);
        writelines(config_label("path") + data_path, config_file, WriteMode="append")
        writelines(config_label("ecg") + fullfile(data_path, file), config_file, WriteMode="append")
        disp('Select BP file')
        [file,data_path] = uigetfile;
        bp.file_path = fullfile(data_path, file);
        writelines(config_label("bp") + fullfile(data_path, file), config_file, WriteMode="append")
        disp('Select SpO2 file')
        [file,data_path] = uigetfile;
        spO2.file_path = fullfile(data_path, file);
        writelines(config_label("spO2") + fullfile(data_path, file), config_file, WriteMode="append")
    end
    
    ecg.signal = readtable(fullfile(ecg.file_path));
    ecg.signal.Properties.VariableNames = mapECGNames(ecg.signal.Properties.VariableNames);
    ecg.channel_names = string(ecg.signal.Properties.VariableNames);
    ecg.Fs = 200;
    ecg.unit = "uV";
   
    bp.signal = readtable(fullfile(bp.file_path));
    bp.channel_names = bp.signal.Properties.VariableNames;
    bp.Fs = 100;
    bp.unit = "mm[Hg]";
    
    spO2.signal = readtable(fullfile(spO2.file_path));
    spO2.channel_names = spO2.signal.Properties.VariableNames;
    spO2.Fs = 50;
    spO2.unit = "";

end

% extract path or file names from config file based on label, e.g. #PATH
function str = findInConfig(lines, label, default, hasToBeFile)
    % Find line with entry for specified label
    i = find(strncmpi(lines, label, strlength(label)));
    if ~isempty(i)
        str_split = split(lines(i), label(end));
        str = str_split(end);
        fprintf("Reading file '%s'\n", label);
    else
        fprintf("No label specified with '%s' found in config file! Using default '%s'\n", label, default);
        str = default;
    end
    % If we expect a data file but the given path doesn't lead to a file
    if hasToBeFile && ~isfile(str)
        [data_path,~,~] = fileparts(default);
        % Try to combine data path with given filename
        if isfile(fullfile(data_path, str))
            str = fullfile(data_path, str);
        elseif isfile(default)
            str = default;
        else
            ME = MException('MyComponent:noSuchFile', 'Data file %s not found!',str);
            throw(ME)
        end
    end
end

function names = mapECGNames(names)
    %new_names = names;
    for i = 1:length(names)
        str_split = split(names(i), 'lead');
        names(i) = str_split(end);
    end
end

% create viewer to display signals with interactive elements
function viewer(ecg, bp, spO2)
    
    %color = dictionary('ecg', {[0.4660 0.6740 0.1880]}, 'bp_a', {[0.8500 0.3250 0.0980]}, 'bp_cv', {[0 0.4470 0.7410]}, 'spO2', {[0.9290 0.6940 0.1250]});
    color = dictionary('ecg', {[0.4660 0.6740 0.1880]}, 'bp_a', {[0.8500 0.3250 0.0980]}, 'bp_cv', {[0.8500 0.3250 0.0980]}, 'spO2', {[0.9290 0.6940 0.1250]});
    fig = uifigure('Name','Waveform Viewer', 'WindowStyle','normal', 'WindowState','maximized');
    %defaultToolbar = findall(fig,'Type','uitoolbar')
    %toolbar = uitoolbar(fig);
    toolbar()

    num_rows = length(ecg.channel_names) + length(bp.channel_names) + length(spO2.channel_names);
    show_plot = true(1,num_rows);
    channel_names = strip([ecg.channel_names, bp.channel_names, spO2.channel_names],'right','_');

    %Create UI grids
    grid = uigridlayout(fig, [2,1]);
    grid.RowHeight = {'1x', 50};
    %grid.ColumnWidth = {'1x'};
    grid.Padding = [0 0 0 0];
    grid.RowSpacing = 0;
    grid.ColumnSpacing = 0;

    grid_signals_ui = uigridlayout(grid, [1,2]);
    grid_signals_ui.ColumnWidth = {'1x', 30};
    grid_signals_ui.Padding = [0 0 0 0];
    grid_signals_ui.RowSpacing = 0;
    grid_signals_ui.ColumnSpacing = 0;

    grid_signals = uigridlayout(grid_signals_ui, [1,1]);
    grid_signals.Padding = [0 0 0 0];
    
    grid_signals_yax = uigridlayout(grid_signals_ui, [4,1]);
    grid_signals_yax.RowHeight = {20,20,'1x',20};
    grid_signals_yax.Padding = [0 40 0 50];
    grid_signals_yax.RowSpacing = 0;

    grid_ui = uigridlayout(grid, [1,3]);
    %grid_ui.RowHeight = {'1x'};
    grid_ui.ColumnWidth = {'1x', '0.1x', '1x'};
    grid_ui.Padding = [10 0 10 0];
    grid_ui.RowSpacing = 0;
    grid_ui.ColumnSpacing = 0;

    grid_ui_cb = uigridlayout(grid_ui, [3, max([length(ecg.channel_names), length(bp.channel_names), length(spO2.channel_names)]) + 1 ]);
    grid_ui_cb.Layout.Column = 1;
    %grid_ui_cb.RowHeight = {'1x', '1x'};
    %grid_ui_cb.ColumnWidth = {'1x', '2x'};
    grid_ui_cb.Padding = [10 0 10 0];
    grid_ui_cb.RowSpacing = 0;
    grid_ui_cb.ColumnSpacing = 0;
    
    grid_ui_toggle = uigridlayout(grid_ui, [1, 1]);
    grid_ui_toggle.Layout.Column = 2;
    %grid_ui_cb.RowHeight = {'1x', '1x'};
    %grid_ui_cb.ColumnWidth = {'1x', '2x'};
    grid_ui_toggle.Padding = [0 0 0 0];
    grid_ui_toggle.RowSpacing = 0;
    grid_ui_toggle.ColumnSpacing = 0;
    % default speed
    xticks_interval_len = 0.2;

    grid_ui_slider = uigridlayout(grid_ui, [2,2]);
    grid_ui_slider.Layout.Column = 3;
    grid_ui_slider.RowHeight = {'1x', '1x'};
    grid_ui_slider.ColumnWidth = {'1x', '5x'};
    grid_ui_slider.Padding = [10 0 10 0];
    grid_ui_slider.RowSpacing = 0;
    grid_ui_slider.ColumnSpacing = 0;

    axes_handles = zeros(1,num_rows);

            
    plot_signals();
    dx = 2; %dx is the width of the axis 'window'
    set(axes_handles(1),'XLim',[0 dx]); %set default window length

    %set(fig,'doublebuffer','on');
    %This avoids flickering when updating the axis
    
    % Generate constants for use in uicontrol initialization
    xmax=max((1:height(ecg.signal)) / ecg.Fs);
    %Create slider to move window
    slider_window_start = uislider(grid_ui_slider,'Limits',[0, xmax-dx],'Value',0,'MajorTicks',[],'MajorTickLabels',{});
    slider_window_start.Layout.Row = 1;
    slider_window_start.Layout.Column = 2;
    
    %Create slider to change window size
    slider_window_length = uislider(grid_ui_slider,'Limits',[0.5, xmax],'Value',dx,'MajorTicks',[],'MajorTickLabels',{}, ...
        'ValueChangingFcn',@(src,event)cb_window_length(src,event,slider_window_start.Value));
    slider_window_length.Layout.Row = 2;
    slider_window_length.Layout.Column = 2;
    
    slider_window_start.ValueChangingFcn = @(src,event)cb_window_start(src,event,slider_window_length.Value);
    
    %Create labels for sliders
    slider_window_start_label = uilabel(grid_ui_slider, 'Text', 'Window position');
    slider_window_start_label.Layout.Row = 1;
    slider_window_start_label.Layout.Column = 1;
    slider_window_length_label = uilabel(grid_ui_slider, 'Text', 'Window length');
    slider_window_length_label.Layout.Row = 2;
    slider_window_length_label.Layout.Column = 1;

    %Create dropdown to select axis for y-axis slider
    %ax_titles = strings(1,num_rows);
    %for ax_i = 1:num_rows
    %    axis = findobj(axes_handles(ax_i),'type','axes');
    %    ax_titles(:,ax_i) = string(axis.Title.String);
    %end
    slider_y_axis_label = uilabel(grid_signals_yax, 'Text', 'y_ax');
    slider_y_axis_label.Layout.Row = 1;
    slider_y_axis_label.Layout.Column = 1;
    slider_y_axis_dropdown = uidropdown(grid_signals_yax,"Items",channel_names,"ValueChangedFcn", @(src,event)cb_y_axis_dd(src,event));
    slider_y_axis_dropdown.ItemsData = [1:length(channel_names)];
    slider_y_axis_dropdown.Layout.Row = 2;
    slider_y_axis_dropdown.Layout.Column = 1;

    %Create slider for y-axis
    y_lims_orig = zeros(2,num_rows);
    for ax_i = 1:num_rows
        axis = findobj(axes_handles(ax_i),'type','axes');
        y_lims_orig(:,ax_i) = axis.YLim;
    end
    slider_y_axis = uislider(grid_signals_yax,'Limits',[0.1, 5],'MajorTicks',[],'MajorTickLabels',{},'Orientation','vertical', ...
        'Value',1,'ValueChangingFcn',@(src,event)cb_y_axis(src,event));
    slider_y_axis.Layout.Row = 3;
    slider_y_axis.Layout.Column = 1;
    slider_y_axis_values = ones(num_rows);

    %Create button to reset y-axis slider
    slider_y_axis_reset_button = uibutton(grid_signals_yax,"Text","Reset","FontSize",8,'ButtonPushedFcn',@(src,event)cb_y_axis_reset_button(src,event));
    slider_y_axis_reset_button.Layout.Row = 4;
    slider_y_axis_reset_button.Layout.Column = 1;

    %Create checkboxes to select which signals to plot
    checkbox_handles = zeros(num_rows + 3, 1);

    % Checkboxes to de-/select all or single ECG signals
    checkbox = uicheckbox(grid_ui_cb,'Text','ECG','Value', 1,'ValueChangedFcn',@(cbx,event)cBoxChangedMult(cbx, 1:length(ecg.channel_names)));
    checkbox.Layout.Row = 1;
    checkbox.Layout.Column = 1;
    checkbox.FontColor = color{'ecg'};
    checkbox.FontWeight = 'bold';
    checkbox_handles(end-2) = checkbox;
    for idx_channel = 1:length(ecg.channel_names)
        checkbox = uicheckbox(grid_ui_cb,'Text',ecg.channel_names(idx_channel),'Value', 1,'ValueChangedFcn',@(cbx,event)cBoxChanged(cbx, idx_channel));
        checkbox.Layout.Row = 1;
        checkbox.Layout.Column = 1 + idx_channel;
        checkbox_handles(idx_channel) = checkbox;
    end

    % Checkboxes to de-/select all or single BP signals
    idx_bp = (idx_channel+1) : (idx_channel+length(bp.channel_names));
    checkbox = uicheckbox(grid_ui_cb,'Text','BP','Value', 1,'ValueChangedFcn',@(cbx,event)cBoxChangedMult(cbx, idx_bp));
    checkbox.Layout.Row = 2;
    checkbox.Layout.Column = 1;
    checkbox.FontColor = color{'bp_a'};
    checkbox.FontWeight = 'bold';
    checkbox_handles(end-1) = checkbox;
    for idx_channel = 1:length(bp.channel_names)
        idx_channel2 = idx_channel + length(ecg.channel_names);
        checkbox = uicheckbox(grid_ui_cb,'Text',bp.channel_names(idx_channel),'Value', 1,'ValueChangedFcn',@(cbx,event)cBoxChanged(cbx, idx_channel2));
        checkbox.Layout.Row = 2;
        checkbox.Layout.Column = 1 + idx_channel;
        checkbox_handles(idx_channel2) = checkbox;
    end

    % Checkboxes to de-/select all or single SpO2 signals
    idx_spO2 = idx_channel2+1 : idx_channel2+length(spO2.channel_names);
    checkbox = uicheckbox(grid_ui_cb,'Text','SpO2','Value', 1,'ValueChangedFcn',@(cbx,event)cBoxChangedMult(cbx, idx_spO2));
    checkbox.Layout.Row = 3;
    checkbox.Layout.Column = 1;
    checkbox.FontColor = color{'spO2'};
    checkbox.FontWeight = 'bold';
    checkbox_handles(end) = checkbox;
    for idx_channel = 1:length(spO2.channel_names)
        idx_channel2 = idx_channel + length(ecg.channel_names) + length(bp.channel_names);
        checkbox = uicheckbox(grid_ui_cb,'Text',spO2.channel_names(idx_channel),'Value', 1,'ValueChangedFcn',@(cbx,event)cBoxChanged(cbx, idx_channel2));
        checkbox.Layout.Row = 3;
        checkbox.Layout.Column =  1 + idx_channel;
        checkbox_handles(idx_channel2) = checkbox;
    end
    
    % Buttons to change scaling of background grid
    bg = uibuttongroup(grid_ui_toggle, 'SelectionChangedFcn', @cb_grid_size);
    b1 = uitogglebutton(bg,'Text','25 mm/s','Position',[3 25 53 20], 'Value', true);
    b2 = uitogglebutton(bg,'Text','50 mm/s','Position',[3 5 53 20]);

    %%%%% functions

    % Callback function to modify XLim of axis based on the position of the slider
    function cb_window_start(src,event,window_length)
        i_true = find(show_plot,1);
        ax = findobj(axes_handles(i_true),'type','axes');
        ax.XLim = event.Value + [0 window_length]; %+[0 get(slider_window_length,''value'')]
    end
    
    % Callback function to modify window length of axis based on the position of the slider
    function cb_window_length(src,event,window_start)
        i_true = find(show_plot,1);
        ax = findobj(axes_handles(i_true),'type','axes');
        ax.XLim = window_start + [0 event.Value]; %+[0 get(slider_window_length,''value'')]
    end
    
    % Callback function to modify y-limits of axis based on the position of the slider
    function cb_y_axis(src,event)
        ax_to_change = slider_y_axis_dropdown.Value;
        %axes_handles_true = axes_handles(show_plot == 1);
        ax = findobj(axes_handles(ax_to_change),'type','axes');
        diff = (y_lims_orig(2,ax_to_change) - y_lims_orig(1,ax_to_change)) / 2;
        %ax.YLim = [mid - event.Value*diff mid+event.Value*diff]; %+[0 get(slider_window_length,''value'')]
        ax.YLim = [y_lims_orig(1,ax_to_change) + diff - event.Value*diff y_lims_orig(2,ax_to_change) - diff + event.Value*diff];
        slider_y_axis_values(ax_to_change) = event.Value;
    end
    % Callback function to modify y-limits of axis based on the position of the slider
    function cb_y_axis_dd(src,event)
        ax_to_change = src.Value;
        slider_y_axis.Value = slider_y_axis_values(ax_to_change);
    end
    % Callback function to reset y-axis
    function cb_y_axis_reset_button(src,event)
        slider_y_axis.Value = 1;
        cb_y_axis([],struct('Value',1));
    end

    % Callback funtion to de-/select plot of a signal
    function cBoxChanged(cbx, index)
        disp(show_plot)
        show_plot(index) = cbx.Value;
        if any(show_plot)
            plot_signals(); 
            i_true = find(show_plot,1); %find first plotted axis
            set(axes_handles(i_true),'XLim',[slider_window_start.Value slider_window_length.Value]); %set xlim to previous value determined by sliders
            if exist("slider_y_axis_dropdown","var")
                slider_y_axis_dropdown.Items = channel_names(show_plot==1);
                arr = [1:length(channel_names)];
                slider_y_axis_dropdown.ItemsData = arr(show_plot==1);
            end
        else % prevent deselection of all signals
            for i = index
                cb_i = findobj(checkbox_handles(i),'type','uicheckbox');
                cb_i.Value = 1;
            end
            cbx.Value=1;
            cBoxChanged(cbx, index);
        end
    end
    % If checkbox de-/selects several signals, check those checkboxes on/off
    function cBoxChangedMult(cbx, index)
        val = cbx.Value;
        for i = index
            cb_i = findobj(checkbox_handles(i),'type','uicheckbox');
            cb_i.Value = val;
        end
        cBoxChanged(cbx, index);
    end
    
    function cb_grid_size(src,event)
        disp("Previous: " + event.OldValue.Text);
        disp("Current: " + event.NewValue.Text);
        if strcmp(event.NewValue.Text, "25 mm/s")
            xticks_interval_len = 0.2;
        elseif strcmp(event.NewValue.Text, "50 mm/s")
            xticks_interval_len = 0.1;
        end
        plot_signals(); 
        i_true = find(show_plot,1); %find first plotted axis
        set(axes_handles(i_true),'XLim',[slider_window_start.Value slider_window_length.Value]); %set xlim to previous value determined by sliders
    end

    function plot_signals()
        num_rows_to_plot = sum(show_plot);
        
        %axes_handles = zeros(1,num_rows_to_plot);
        
        if(num_rows_to_plot > 0)
        tiled_layout = tiledlayout(grid_signals, num_rows_to_plot, 1);
        tiled_layout.Layout.Row = 1;
        tiled_layout.Layout.Column = 2;
        tiled_layout.Padding = 'tight';
        tiled_layout.TileSpacing = 'tight';%'none';

        nr_signals_plotted = 0; %counter for plots
        %plot ecg signals
        for i = 1:length(ecg.channel_names)
            if(show_plot(i))
                nr_signals_plotted = nr_signals_plotted + 1;
                tm = (1:height(ecg.signal)) / ecg.Fs;
                %ax = uiaxes(grid_signals,'NextPlot','replace');
                ax = nexttile(tiled_layout, nr_signals_plotted);
                %axes_handles(nr_signals_plotted) = ax;
                axes_handles(i) = ax;
                channel_i = table2array(ecg.signal(:, ecg.channel_names{i}));
                channel_i = channel_i / 1000;
                plothandles(nr_signals_plotted) = plot(ax,tm, channel_i, 'Color', color{'ecg'});
                [~,qrs_i,~] = pan_tompkin(channel_i,ecg.Fs,0);
                hold(ax, 'on' )
                plot(ax,tm(qrs_i),channel_i(qrs_i),'rx');
                ax.TitleFontSizeMultiplier = 0.9;
                ax.Title.String = ecg.channel_names(i);
                ax.YLabel.String = ecg.unit;
                ax.XTick = 0:xticks_interval_len:tm(end);
                ax.XTickLabel = {};
                ax.XGrid = 'on';
                ax.YGrid = 'on';
                ax.YLim = [min(channel_i) max(channel_i)];

                %yt = yticks;
                %yticks(yt(1):500:yt(end))
                %yt = yticks;
                %disp(yt)
            end
        end
        if(any(show_plot(1:length(ecg.channel_names))))
            annotation(grid_signals,'TextArrow', [.97 .97], [.95 .95], 'String',sprintf('HRV: %d', hrv_rmssd(qrs_i)), 'HeadStyle','none','TextBackgroundColor','w' );
        end
        %plot blood pressure signals
        for i = 1:length(bp.channel_names)
            i2 = length(ecg.channel_names)+i;
            if show_plot(i2)
                nr_signals_plotted = nr_signals_plotted + 1;
                tm = (1:height(bp.signal)) / bp.Fs;
                %ax = uiaxes(grid_signals);
                ax = nexttile(tiled_layout, nr_signals_plotted);
                axes_handles(i2) = ax;
                channel_i = table2array(bp.signal(:, bp.channel_names{i}));
                if i == 1
                    plothandles(nr_signals_plotted) = plot(ax,tm, channel_i, 'Color', color{'bp_a'});
                    hold(ax, 'on' )
                    [~,peakp,~]=delineator(channel_i,bp.Fs); % Requires curve fitting toolbox
                    plot(ax,tm(peakp),channel_i(peakp),'rx');
                else
                    plothandles(nr_signals_plotted) = plot(ax,tm, channel_i, 'Color', color{'bp_cv'});
                end
                ax.TitleFontSizeMultiplier = 0.9;
                ax.Title.String = bp.channel_names(i);
                ax.YLabel.String = bp.unit;
                ax.XTick = 0:xticks_interval_len:tm(end);
                ax.XTickLabel = {};
                ax.XGrid = 'on';
                ax.YGrid = 'on';
                ax.YLim = [min(channel_i) max(channel_i)];
            end
        end

        %plot spO2 signals
        for i = 1:length(spO2.channel_names)
            i2 = length(ecg.channel_names)+length(bp.channel_names)+i;
            if show_plot(i2)
                nr_signals_plotted = nr_signals_plotted + 1;
                tm = (1:height(spO2.signal)) / spO2.Fs;
                %ax = uiaxes(grid_signals);
                ax = nexttile(tiled_layout, nr_signals_plotted);
                axes_handles(i2) = ax;
                channel_i = table2array(spO2.signal(:, spO2.channel_names{i}));
                plothandles(nr_signals_plotted) = plot(ax,tm, channel_i, 'Color', color{'spO2'});
                ax.TitleFontSizeMultiplier = 0.9;
                ax.Title.String = spO2.channel_names(i);
                ax.YLabel.String = spO2.unit;
                ax.XTick = 0:xticks_interval_len:tm(end);
                if i < length(spO2.channel_names)
                    ax.XTickLabel = {};
                else
                    ax.XLabel.String = 'time [s]';
                end
                ax.XGrid = 'on';
                ax.YGrid = 'on';
                ax.YLim = [min(channel_i) max(channel_i)];
            end
        end

        set(axes_handles(show_plot == 1),'GridColor',[0.8 0.55 0.55], 'GridLineWidth', 2) % color like ECG paper
        linkaxes(axes_handles,'x');

        %Update items in dropdown to scale y-axis
        %Create dropdown to select axis for slider for y-axis
        %ax_titles = strings(1,nr_signals_plotted);
        %for ax_i = 1:nr_signals_plotted
        %    axis = findobj(axes_handles(ax_i),'type','axes');
        %    ax_titles(:,ax_i) = string(axis.Title.String);
        %end
        %if ~exist('ax_titles','var')
        %    ax_titles = strings(1,num_rows);
        %    for ax_i = 1:num_rows
        %        axis = findobj(axes_handles(ax_i),'type','axes');
        %        ax_titles(:,ax_i) = string(axis.Title.String);
        %    end
        %end
        %temp=ax_titles;
        end
    end

    function toolbar()
        % Create a File menu
        fileMenu = uimenu(fig, 'Text', 'File');
        % Add menu items to the File menu
        uimenu(fileMenu, 'Text', 'Save', 'MenuSelectedFcn', @(src, event) menu_save_fig);
        uimenu(fileMenu, 'Text', 'Save As', 'MenuSelectedFcn', @(src, event) menu_save_fig_as);
    end
 
    function menu_save_fig(src,event)
        %exportgraphics(fig,"test.pdf");
        save_path = fullfile(pwd,"waveform_viewer.jpg");
        exportapp(fig,save_path);
        fprintf("Image saved as '%s'\n", save_path);
    end
    function menu_save_fig_as(src,event)
        %file = uigetfile('*.txt');
        filter = {'*.jpg';'*.png';'*.tif';'*.pdf';'*.eps'};
        [file_name,file_path] = uiputfile(filter);
        save_path = fullfile(file_path,file_name);
        if ischar(file_name)
            exportapp(fig,save_path);
        end
        fprintf("Image saved as '%s'\n", save_path);
    end
    
    % Heart rate variability based on root mean sum of squared distance
    function rmssd = hrv_rmssd(qrs_i)
        % squared values of successive differences
        SquaredDiffValues = diff(qrs_i).^2;
        % square root of SquaredDiffValues
        rmssd = sqrt(mean(SquaredDiffValues));
    end

end
