function varargout = panel_ieeg(varargin)
% PANEL_IEEG: Create a panel to edit SEEG/ECOG contact positions.
% 
% USAGE:  bstPanelNew = panel_ieeg('CreatePanel')
%                       panel_ieeg('UpdatePanel')
%                       panel_ieeg('UpdateElecList')
%                       panel_ieeg('UpdateElecProperties')
%                       panel_ieeg('CurrentFigureChanged_Callback')

% @=============================================================================
% This function is part of the Brainstorm software:
% http://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2017 University of Southern California & McGill University
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPLv3
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% 
% FOR RESEARCH PURPOSES ONLY. THE SOFTWARE IS PROVIDED "AS IS," AND THE
% UNIVERSITY OF SOUTHERN CALIFORNIA AND ITS COLLABORATORS DO NOT MAKE ANY
% WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY
% LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
%
% For more information type "brainstorm license" at command prompt.
% =============================================================================@
%
% Authors: Francois Tadel, 2017

eval(macro_method);
end


%% ===== CREATE PANEL =====
function bstPanelNew = CreatePanel() %#ok<DEFNU>
    panelName = 'iEEG';
    % Java initializations
    import java.awt.*;
    import javax.swing.*;
    import org.brainstorm.icon.*;
    % Create tools panel
    jPanelNew = gui_component('Panel');
    jPanelTop = gui_component('Panel');
    jPanelNew.add(jPanelTop, BorderLayout.NORTH);
    TB_DIM = java_scaled('dimension',25,25);
    
    % ===== TOOLBAR =====
    jMenuBar = gui_component('MenuBar', jPanelTop, BorderLayout.NORTH);
        jToolbar = gui_component('Toolbar', jMenuBar);
        jToolbar.setPreferredSize(TB_DIM);
        jToolbar.setOpaque(0);
        % Add/remove
        gui_component('ToolbarButton', jToolbar,[],[], {IconLoader.ICON_PLUS, TB_DIM}, 'Add new electrode', @(h,ev)bst_call(@AddElectrode));
        gui_component('ToolbarButton', jToolbar,[],[], {IconLoader.ICON_MINUS, TB_DIM}, 'Remove selected electrodes', @(h,ev)bst_call(@RemoveElectrode));
        % Set color
        jToolbar.addSeparator();
        gui_component('ToolbarButton', jToolbar,[],[], {IconLoader.ICON_COLOR_SELECTION, TB_DIM}, 'Select color for selected electrodes', @(h,ev)bst_call(@EditElectrodeColor));
        % Show/Hide
        jButtonShow = gui_component('ToolbarToggle', jToolbar, [], [], {IconLoader.ICON_DISPLAY, TB_DIM}, 'Show/hide selected electrodes', @(h,ev)bst_call(@SetElectrodeVisible, ev.getSource().isSelected()));
        jButtonShow.setSelected(1);
        % Set display mode
        jToolbar.addSeparator();
        jButtonGroup = ButtonGroup();
        jRadioDispDepth  = gui_component('ToolbarToggle', jToolbar, [], [], {IconLoader.ICON_SEEG_DEPTH,  jButtonGroup, TB_DIM}, 'Display contacts as SEEG electrodes/ECOG strips', @(h,ev)bst_call(@SetDisplayMode, 'depth'));
        jRadioDispSphere = gui_component('ToolbarToggle', jToolbar, [], [], {IconLoader.ICON_SEEG_SPHERE, jButtonGroup, TB_DIM}, 'Display contacts as spheres', @(h,ev)bst_call(@SetDisplayMode, 'sphere'));
        % Menu: Contacts
        jToolbar.addSeparator();
        jMenuContacts = gui_component('Menu', jMenuBar, [], 'Contacts', IconLoader.ICON_MENU, [], [], 11);
        jMenuContacts.setBorder(BorderFactory.createEmptyBorder(0,2,0,2));
        
    % ===== PANEL MAIN =====
    jPanelMain = gui_component('Panel');
    jPanelMain.setBorder(BorderFactory.createEmptyBorder(7,7,7,7));
%         % ===== VERTICAL TOOLBAR =====
%         jToolbar2 = gui_component('Toolbar', jPanelMain, BorderLayout.EAST);
%         jToolbar2.setOrientation(jToolbar.VERTICAL);
%         jToolbar2.setPreferredSize(java_scaled('dimension',26,20));
%         jToolbar2.setBorder([]);

        % ===== FIRST PART =====
        jPanelFirstPart = gui_component('Panel');
            % ===== ELECTRODES LIST =====
            jPanelElecList = gui_component('Panel');
                jBorder = java_scaled('titledborder', 'Electrodes');
                jPanelElecList.setBorder(jBorder);
                % Electrodes list
                jListElec = java_create('org.brainstorm.list.BstClusterList');
                jListElec.setBackground(Color(.9,.9,.9));
                jListElec.setLayoutOrientation(jListElec.VERTICAL_WRAP);
                jListElec.setVisibleRowCount(-1);
                java_setcb(jListElec, ...
                    'ValueChangedCallback', @(h,ev)bst_call(@ElecListValueChanged_Callback,h,ev), ...
                    'KeyTypedCallback',     @(h,ev)bst_call(@ElecListKeyTyped_Callback,h,ev), ...
                    'MouseClickedCallback', @(h,ev)bst_call(@ElecListClick_Callback,h,ev));
                jPanelScrollList = JScrollPane();
                jPanelScrollList.getLayout.getViewport.setView(jListElec);
                jPanelScrollList.setBorder([]);
                jPanelElecList.add(jPanelScrollList);
            jPanelFirstPart.add(jPanelElecList, BorderLayout.CENTER);
        jPanelMain.add(jPanelFirstPart);

        jPanelBottom = gui_river([0,0], [0,0,0,0]);
            % ===== ELECTRODE OPTIONS =====
            jPanelElecOptions = gui_river([3,3], [0,5,10,3], 'Electrode configuration');
                % Electrode type
                gui_component('label', jPanelElecOptions, '', 'Type: ');
                jButtonGroup = ButtonGroup();
                jRadioSeeg = gui_component('radio', jPanelElecOptions, '', 'SEEG', jButtonGroup, '', @(h,ev)ValidateOptions('Type', ev.getSource()));
                jRadioEcog = gui_component('radio', jPanelElecOptions, '', 'ECOG', jButtonGroup, '', @(h,ev)ValidateOptions('Type', ev.getSource()));
                % Electrode model
                jPanelModel = gui_river([0,0], [0,0,0,0]);
                    % Title
                    gui_component('label', jPanelModel, '', 'Model: ');
                    % Combo box
                    jComboModel = gui_component('combobox', jPanelModel, 'hfill', [], [], [], []);
                    jComboModel.setFocusable(0);
                    jComboModel.setMaximumRowCount(15);
                    jComboModel.setPreferredSize(java_scaled('dimension',30,20));
                    % ComboBox change selection callback
                    jModel = jComboModel.getModel();
                    java_setcb(jModel, 'ContentsChangedCallback', @(h,ev)bst_call(@ComboModelChanged_Callback,h,ev));
                    % Add/remove models
                    gui_component('button', jPanelModel,'right',[], {IconLoader.ICON_PLUS, java_scaled('dimension',22,22)}, 'Add new electrode model', @(h,ev)bst_call(@AddElectrodeModel));
                    gui_component('button', jPanelModel,[],[], {IconLoader.ICON_MINUS, java_scaled('dimension',22,22)}, 'Remove electrode model', @(h,ev)bst_call(@RemoveElectrodeModel));
                jPanelElecOptions.add('br hfill', jPanelModel);

                % Number of contacts
                gui_component('label', jPanelElecOptions, 'br', 'Number of contacts: ');
                jTextNcontacts = gui_component('text', jPanelElecOptions, 'tab', '');
                jTextNcontacts.setHorizontalAlignment(jTextNcontacts.RIGHT);
                % Contacts spacing
                gui_component('label', jPanelElecOptions, 'br', 'Contact spacing: ');
                jTextSpacing = gui_component('text', jPanelElecOptions, 'tab', '');
                jTextSpacing.setHorizontalAlignment(jTextNcontacts.RIGHT);
                gui_component('label', jPanelElecOptions, '', 'mm');
                % Contacts length
                jLabelContactLength = gui_component('label', jPanelElecOptions, 'br', 'Contact length: ');
                jTextContactLength  = gui_component('texttime', jPanelElecOptions, 'tab', '');
                gui_component('label', jPanelElecOptions, '', 'mm');
                % Contacts diameter
                gui_component('label', jPanelElecOptions, 'br', 'Contact diameter: ');
                jTextContactDiam = gui_component('texttime', jPanelElecOptions, 'tab', '');
                gui_component('label', jPanelElecOptions, '', 'mm');
                % Electrode diameter
                jLabelElecDiameter = gui_component('label', jPanelElecOptions, 'br', 'Electrode diameter: ');
                jTextElecDiameter  = gui_component('texttime', jPanelElecOptions, 'tab', '');
                jLabelElecDiamUnits = gui_component('label', jPanelElecOptions, '', 'mm');
                % Electrode length
                jLabelElecLength = gui_component('label', jPanelElecOptions, 'br', 'Electrode length: ');
                jTextElecLength  = gui_component('texttime', jPanelElecOptions, 'tab', '');
                jLabelElecLengthUnits = gui_component('label', jPanelElecOptions, '', 'mm');
                % Set electrode position
                jButtonSet1 = gui_component('button', jPanelElecOptions, 'br center', 'Set tip',   [], 'Set electrode tip (MRI Viewer)', @(h,ev)bst_call(@SetElectrodeLoc, 1));
                jButtonSet2 = gui_component('button', jPanelElecOptions, 'center', 'Set skull entry', [], 'Set electrode entry point in the skull (MRI Viewer)', @(h,ev)bst_call(@SetElectrodeLoc, 2));
            jPanelBottom.add('hfill', jPanelElecOptions);
        jPanelMain.add(jPanelBottom, BorderLayout.SOUTH)
    jPanelNew.add(jPanelMain, BorderLayout.CENTER);
    
    % Store electrode selection
    jLabelSelectElec = JLabel('');
    % Create the BstPanel object that is returned by the function
    bstPanelNew = BstPanel(panelName, ...
                           jPanelNew, ...
                           struct('jPanelElecList',      jPanelElecList, ...
                                  'jToolbar',            jToolbar, ...
                                  'jPanelElecOptions',   jPanelElecOptions, ...
                                  'jButtonShow',         jButtonShow, ...
                                  'jRadioDispDepth',     jRadioDispDepth, ...
                                  'jRadioDispSphere',    jRadioDispSphere, ...
                                  'jMenuContacts',       jMenuContacts, ...
                                  'jListElec',           jListElec, ...
                                  'jComboModel',         jComboModel, ...
                                  'jRadioSeeg',          jRadioSeeg, ...
                                  'jRadioEcog',          jRadioEcog, ...
                                  'jTextNcontacts',      jTextNcontacts, ...
                                  'jTextSpacing',        jTextSpacing, ...
                                  'jTextContactDiam',    jTextContactDiam, ...
                                  'jLabelContactLength', jLabelContactLength, ...
                                  'jTextContactLength',  jTextContactLength, ...
                                  'jLabelElecLength',    jLabelElecLength, ...
                                  'jTextElecLength',     jTextElecLength, ...
                                  'jLabelElecLengthUnits',jLabelElecLengthUnits, ...
                                  'jLabelElecDiameter',  jLabelElecDiameter, ...
                                  'jTextElecDiameter',   jTextElecDiameter, ...
                                  'jLabelElecDiamUnits', jLabelElecDiamUnits, ...
                                  'jLabelSelectElec',    jLabelSelectElec));
                              
    
                              
%% =================================================================================
%  === INTERNAL CALLBACKS  =========================================================
%  =================================================================================
        
    %% ===== MODEL SELECTION =====
    function ComboModelChanged_Callback(varargin)
        % Get selected model
        [iModel, sModels] = GetSelectedModel();
        % Get the selected electrode
        [sSelElec, iSelElec] = GetSelectedElectrodes();
        % Reset Model field
        if isempty(iModel)
            [sSelElec.Model] = deal([]);
        % Copy model values to electrodes
        else
            for i = 1:length(sSelElec)
                sSelElec(i).Model = sModels(iModel).Model;
                if ~isempty(sModels(iModel).ContactNumber)
                    sSelElec(i).ContactNumber = sModels(iModel).ContactNumber;
                end
                if ~isempty(sModels(iModel).ContactSpacing)
                    sSelElec(i).ContactSpacing = sModels(iModel).ContactSpacing;
                end
                if ~isempty(sModels(iModel).ContactDiameter)
                    sSelElec(i).ContactDiameter = sModels(iModel).ContactDiameter;
                end
                if ~isempty(sModels(iModel).ContactLength)
                    sSelElec(i).ContactLength = sModels(iModel).ContactLength;
                end
                if ~isempty(sModels(iModel).ElecDiameter)
                    sSelElec(i).ElecDiameter = sModels(iModel).ElecDiameter;
                end
                if ~isempty(sModels(iModel).ContactNumber)
                    sSelElec(i).ElecLength = sModels(iModel).ElecLength;
                end
            end
        end
        % Update electrode properties
        SetElectrodes(iSelElec, sSelElec);
        % Update display
        UpdateElecProperties(0);
    end

    %% ===== LIST SELECTION CHANGED CALLBACK =====
    function ElecListValueChanged_Callback(h, ev)
        if ~ev.getValueIsAdjusting()
            UpdateElecProperties();
        end
    end

    %% ===== LIST KEY TYPED CALLBACK =====
    function ElecListKeyTyped_Callback(h, ev)
        switch(uint8(ev.getKeyChar()))
            % DELETE
            case {ev.VK_DELETE, ev.VK_BACK_SPACE}
                RemoveElectrode();
            case ev.VK_ESCAPE
                SetSelectedElectrodes(0);
        end
    end

    %% ===== LIST CLICK CALLBACK =====
    function ElecListClick_Callback(h, ev)
        % If DOUBLE CLICK
        if (ev.getClickCount() == 2)
            % Rename selection
            EditElectrodeLabel();
        end
    end
end
                   


%% =================================================================================
%  === EXTERNAL PANEL CALLBACKS  ===================================================
%  =================================================================================
%% ===== CURRENT FIGURE CHANGED =====
function CurrentFigureChanged_Callback(hFig) %#ok<DEFNU>
    UpdatePanel();
end

%% ===== UPDATE CALLBACK =====
function UpdatePanel()
    % Get panel controls
    ctrl = bst_get('PanelControls', 'iEEG');
    if isempty(ctrl)
        return;
    end
    % Get current electrodes
    [sElectrodes, iDS, iFig, hFig] = GetElectrodes();
    % If a surface is available for current figure
    if ~isempty(sElectrodes)
        gui_enable([ctrl.jPanelElecList, ctrl.jToolbar], 1);
        ctrl.jListElec.setBackground(java.awt.Color(1,1,1));
    % Else : no figure associated with the panel : disable all controls
    else
        gui_enable([ctrl.jPanelElecList, ctrl.jToolbar], 0);
        ctrl.jListElec.setBackground(java.awt.Color(.9,.9,.9));
    end
    % Select appropriate display mode button
    if ~isempty(hFig)
        ElectrodeDisplay = getappdata(hFig, 'ElectrodeDisplay');
        if strcmpi(ElectrodeDisplay.DisplayMode, 'depth')
            ctrl.jRadioDispDepth.setSelected(1);
        else
            ctrl.jRadioDispSphere.setSelected(1);
        end
    end
    % Disable options panel until an electrode is selected
    gui_enable(ctrl.jPanelElecOptions, 0);
    % Update JList
    [iDS, iFig, hFig] = UpdateElecList();
    % Update "contacts" menu
    UpdateMenus(iDS, iFig);
end


%% ===== UPDATE ELECTRODE LIST =====
function [iDS, iFig, hFig] = UpdateElecList()
    import org.brainstorm.list.*;
    % Get current electrodes
    [sElectrodes, iDS, iFig, hFig] = GetElectrodes();
    % Get panel controls
    ctrl = bst_get('PanelControls', 'iEEG');
    if isempty(ctrl)
        return;
    end
    % Create a new empty list
    listModel = java_create('javax.swing.DefaultListModel');
    % Get font with which the list is rendered
    fontSize = round(11 * bst_get('InterfaceScaling') / 100);
    jFont = java.awt.Font('Dialog', java.awt.Font.PLAIN, fontSize);
    tk = java.awt.Toolkit.getDefaultToolkit();
    % Add an item in list for each electrode
    Wmax = 0;
    for i = 1:length(sElectrodes)
        % itemType  = num2str(sElectrodes(i).ContactNumber);
        itemType  = '';
        if sElectrodes(i).Visible
            itemText  = sElectrodes(i).Name;
            itemColor = sElectrodes(i).Color;
        else
            itemText  = ['<HTML><FONT color="#a0a0a0">' sElectrodes(i).Name '</FONT>'];
            itemColor = [.63 .63 .63];
        end
        listModel.addElement(BstListItem(itemType, [], itemText, i, itemColor(1), itemColor(2), itemColor(3)));
        % Get longest string
        W = tk.getFontMetrics(jFont).stringWidth(sElectrodes(i).Name);
        if (W > Wmax)
            Wmax = W;
        end
    end
    % Update list model
    ctrl.jListElec.setModel(listModel);
    % Update cell rederer based on longest channel name
    ctrl.jListElec.setCellRenderer(java_create('org.brainstorm.list.BstClusterListRenderer', 'II', fontSize, Wmax + 28));
end


%% ===== UPDATE MODEL LIST =====
function UpdateModelList(elecType)
    import org.brainstorm.list.*;
    % Get panel controls
    ctrl = bst_get('PanelControls', 'iEEG');
    if isempty(ctrl)
        return;
    end
    % Get the available electrode models
    sModels = GetElectrodeModels();
    % Show only the models from the selected modality
    if ~isempty(elecType)
        iMod = find(strcmpi({sModels.Type}, elecType));
        sModels = sModels(iMod);
    end
    % Sort names alphabetically
    elecModels = sort({sModels.Model});
    % Save combobox callback
    jModel = ctrl.jComboModel.getModel();
    bakCallback = java_getcb(jModel, 'ContentsChangedCallback');
    java_setcb(jModel, 'ContentsChangedCallback', []);
    % Empty the ComboBox
    ctrl.jComboModel.removeAllItems();
    % Add all entries in the combo box
    ctrl.jComboModel.addItem(BstListItem('', '', '', 0));
    for i = 1:length(elecModels)
        ctrl.jComboModel.addItem(BstListItem('', '', elecModels{i}, i));
    end
    % Restore callback
    java_setcb(jModel, 'ContentsChangedCallback', bakCallback);
end


%% ===== UPDATE ELECTRODE PROPERTIES =====
function UpdateElecProperties(isUpdateModelList)
    % Parse inputs
    if (nargin < 1) || isempty(isUpdateModelList)
        isUpdateModelList = 1;
    end
    % Get panel controls
    ctrl = bst_get('PanelControls', 'iEEG');
    if isempty(ctrl)
        return;
    end
    % Get selected electrodes
    [sSelElec, iSelElec] = GetSelectedElectrodes();
    % Enable panel if something is selected
    gui_enable(ctrl.jPanelElecOptions, ~isempty(sSelElec));
    
    % Select ECOG/SEEG
    if (length(sSelElec) == 1) || ((length(sSelElec) > 1) && all(cellfun(@(c)isequal(c,sSelElec(1).Type), {sSelElec.Type})))
        if strcmpi(sSelElec(1).Type, 'SEEG')
            ctrl.jRadioSeeg.setSelected(1);
            elecType = 'SEEG';
        elseif strcmpi(sSelElec(1).Type, 'ECOG')
            ctrl.jRadioEcog.setSelected(1);
            elecType = 'ECOG';
        else
            elecType = [];
        end
    else
        ctrl.jRadioSeeg.setSelected(0);
        ctrl.jRadioEcog.setSelected(0);
        elecType = [];
    end
    % Update list of models
    if isUpdateModelList
        % Update list of electrode models
        UpdateModelList(elecType);
        % Select electrode model
        if (length(sSelElec) == 1) || ((length(sSelElec) > 1) && all(cellfun(@(c)isequal(c,sSelElec(1).Model), {sSelElec.Model})))
            SetSelectedModel(sSelElec(1).Model);
        else
            SetSelectedModel([]);
        end
    end
    
    % Update control labels
    if ~isempty(sSelElec) && strcmpi(sSelElec(1).Type, 'SEEG')
        ctrl.jLabelContactLength.setText('Contact length: ');
        ctrl.jLabelElecLength.setVisible(1);
        ctrl.jTextElecLength.setVisible(1);
        ctrl.jLabelElecLengthUnits.setVisible(1);
        ctrl.jLabelElecDiameter.setText('Electrode diameter: ');
        ctrl.jLabelElecDiamUnits.setText('mm');
    else
        ctrl.jLabelContactLength.setText('Contact height: ');
        ctrl.jLabelElecLength.setVisible(0);
        ctrl.jTextElecLength.setVisible(0);
        ctrl.jLabelElecLengthUnits.setVisible(0);
        ctrl.jLabelElecDiameter.setText('Wire width: ');
        ctrl.jLabelElecDiamUnits.setText('points');
    end
    
    % Number of contacts
    if (length(sSelElec) == 1) || ((length(sSelElec) > 1) && all(cellfun(@(c)isequal(c,sSelElec(1).ContactNumber), {sSelElec.ContactNumber})))
        valContacts = sSelElec(1).ContactNumber;
    else
        valContacts = [];
    end
    % Contact spacing
    if (length(sSelElec) == 1) || ((length(sSelElec) > 1) && all(cellfun(@(c)isequal(c,sSelElec(1).ContactSpacing), {sSelElec.ContactSpacing})))
        valSpacing = sSelElec(1).ContactSpacing * 1000;
    else
        valSpacing = [];
    end
    % Contact length
    if (length(sSelElec) == 1) || ((length(sSelElec) > 1) && all(cellfun(@(c)isequal(c,sSelElec(1).ContactLength), {sSelElec.ContactLength})))
        valContactLength = sSelElec(1).ContactLength * 1000;
    else
        valContactLength = [];
    end
    % Contact diameter
    if (length(sSelElec) == 1) || ((length(sSelElec) > 1) && all(cellfun(@(c)isequal(c,sSelElec(1).ContactDiameter), {sSelElec.ContactDiameter})))
        valContactDiam = sSelElec(1).ContactDiameter * 1000;
    else
        valContactDiam = [];
    end
    % Electrode diameter
    if (length(sSelElec) == 1) || ((length(sSelElec) > 1) && all(cellfun(@(c)isequal(c,sSelElec(1).ElecDiameter), {sSelElec.ElecDiameter})))
        valElecDiameter = sSelElec(1).ElecDiameter * 1000;
    else
        valElecDiameter = [];
    end
    % Electrode length
    if (length(sSelElec) == 1) || ((length(sSelElec) > 1) && all(cellfun(@(c)isequal(c,sSelElec(1).ElecLength), {sSelElec.ElecLength})))
        valElecLength = sSelElec(1).ElecLength * 1000;
    else
        valElecLength = [];
    end
    % Update panel
    gui_validate_text(ctrl.jTextNcontacts,     [], [], {1,1024,1}, 'list',     0, valContacts,      @(h,ev)ValidateOptions('ContactNumber', ctrl.jTextNcontacts));
    gui_validate_text(ctrl.jTextSpacing,       [], [], {0,100,10}, 'list',     1, valSpacing,       @(h,ev)ValidateOptions('ContactSpacing', ctrl.jTextSpacing));
    gui_validate_text(ctrl.jTextContactLength, [], [], {0,30,10},  'optional', 1, valContactLength, @(h,ev)ValidateOptions('ContactLength', ctrl.jTextContactLength));
    gui_validate_text(ctrl.jTextContactDiam,   [], [], {0,20,10},  'optional', 1, valContactDiam,   @(h,ev)ValidateOptions('ContactDiameter', ctrl.jTextContactDiam));
    gui_validate_text(ctrl.jTextElecDiameter,  [], [], {0,20,10},  'optional', 1, valElecDiameter,  @(h,ev)ValidateOptions('ElecDiameter', ctrl.jTextElecDiameter));
    gui_validate_text(ctrl.jTextElecLength,    [], [], {0,200,10}, 'optional', 1, valElecLength,    @(h,ev)ValidateOptions('ElecLength', ctrl.jTextElecLength));
    % Select show button
    isSelected = ~isempty(sSelElec) && all([sSelElec.Visible] == 1);
    ctrl.jButtonShow.setSelected(isSelected);
    % Save selected electrodes
    ctrl.jLabelSelectElec.setText(num2str(iSelElec));
end


%% ===== GET SELECTED ELECTRODES =====
function [sSelElec, iSelElec, iDS, iFig, hFig] = GetSelectedElectrodes()
    sSelElec = [];
    iSelElec = [];
    iDS = [];
    iFig = [];
    hFig = [];
    % Get panel handles
    ctrl = bst_get('PanelControls', 'iEEG');
    if isempty(ctrl)
        return;
    end
    % Get all electrodes
    [sElectrodes, iDS, iFig, hFig] = GetElectrodes();
    if isempty(sElectrodes)
        return
    end
    % Get JList selected indices
    iSelElec = uint16(ctrl.jListElec.getSelectedIndices())' + 1;
    sSelElec = sElectrodes(iSelElec);
end


%% ===== SET SELECTED ELECTRODES =====
function SetSelectedElectrodes(iSelElec)
    % === GET ELECTRODE INDICES ===
    % No selection
    if isempty(iSelElec) || (any(iSelElec == 0))
        iSelItem = -1;
    % Find the selected electrode in the JList
    else
        iSelItem = iSelElec - 1;
    end
    % === CHECK FOR MODIFICATIONS ===
    % Get figure controls
    ctrl = bst_get('PanelControls', 'iEEG');
    if isempty(ctrl) || isempty(ctrl.jListElec)
        return
    end
    % Get previous selection
    iPrevItems = ctrl.jListElec.getSelectedIndices();
    % If selection did not change: exit
    if isequal(iPrevItems, iSelItem) || (isempty(iPrevItems) && isequal(iSelItem, -1))
        return
    end
    % === UPDATE SELECTION ===
    % Temporality disables JList selection callback
    jListCallback_bak = java_getcb(ctrl.jListElec, 'ValueChangedCallback');
    java_setcb(ctrl.jListElec, 'ValueChangedCallback', []);
    % Select items in JList
    ctrl.jListElec.setSelectedIndices(iSelItem);
    % Scroll to see the last selected electrode in the list
    if (length(iSelItem) >= 1) && ~isequal(iSelItem, -1)
        selRect = ctrl.jListElec.getCellBounds(iSelItem(end), iSelItem(end));
        ctrl.jListElec.scrollRectToVisible(selRect);
        ctrl.jListElec.repaint();
    end
    % Restore JList callback
    java_setcb(ctrl.jListElec, 'ValueChangedCallback', jListCallback_bak);
    % Update panel fields
    UpdateElecProperties();
end


%% ===== SHOW MENU =====
function UpdateMenus(iDS, iFig)
    import org.brainstorm.icon.*;
    global GlobalData;
    % Get panel controls
    ctrl = bst_get('PanelControls', 'iEEG');
    if isempty(ctrl)
        return;
    end
    jMenu = ctrl.jMenuContacts;
    % Get modality
    Modality = GlobalData.DataSet(iDS).Figure(iFig).Id.Modality;
    % Remove all previous menus
    jMenu.removeAll();
    % Menu: Default positions
    gui_component('MenuItem', jMenu, [], 'Set default positions', IconLoader.ICON_SEEG_DEPTH, [], @(h,ev)bst_call(@AlignContacts, iDS, iFig, 'default'));
    % Menu: Export select atlas
    if strcmpi(Modality, 'ECOG')
        
    elseif strcmpi(Modality, 'SEEG')
        gui_component('MenuItem', jMenu, [], 'Project on electrode', IconLoader.ICON_SEEG_DEPTH, [], @(h,ev)bst_call(@AlignContacts, iDS, iFig, 'project'));
    end
    % Menu: Export positions
    jMenu.addSeparator();
    gui_component('MenuItem', jMenu, [], 'Export selected contacts', IconLoader.ICON_SAVE, [], @(h,ev)bst_call(@ExportChannelFile, 'selected'));            
    gui_component('MenuItem', jMenu, [], 'Export all contacts', IconLoader.ICON_SAVE, [],      @(h,ev)bst_call(@ExportChannelFile, 'all'));      
end


%% ===== GET COLOR TABLE =====
function ColorTable = GetElectrodeColorTable()
    ColorTable = [0    .8    0   ;
                  1    0     0   ; 
                  .4   .4    1   ;
                  1    .694  .392;
                  0    1     1   ;
                  1    0     1   ;
                  .4   0     0   ; 
                  0    .4    0   ;
                  1    .843  0   ];
end


%% ===== EDIT ELECTRODE LABEL =====
% Rename one and only one selected electrode
function EditElectrodeLabel(varargin)
    % Get selected electrodes
    [sSelElec, iSelElec] = GetSelectedElectrodes();
    % Get all electrodes
    sAllElec = GetElectrodes();
    % Warning message if no electrode selected
    if isempty(sAllElec)
        java_dialog('warning', 'No electrodes selected.', 'Rename selected electrodes');
        return;
    % If more than one electrode selected: keep only the first one
    elseif (length(sSelElec) > 1)
        iSelElec = iSelElec(1);
        sSelElec = sSelElec(1);
        SetSelectedElectrodes(iSelElec);
    end
    % Ask user for a new label
    newLabel = java_dialog('input', sprintf('Enter a new label for electrode "%s":', sSelElec.Name), ...
                             'Rename selected electrode', [], sSelElec.Name);
    if isempty(newLabel) || strcmpi(newLabel, sSelElec.Name)
        return
    end
    % Check if if already exists
    if any(strcmpi({sAllElec.Name}, newLabel))
        java_dialog('warning', ['Electrode "' newLabel '" already exists.'], 'Rename selected electrode');
        return;
    end
    % Update electrode definition
    sSelElec.Name = newLabel;
    % Save modifications
    SetElectrodes(iSelElec, sSelElec);
    % Update JList
    UpdateElecList();
    % Select again electrode
    SetSelectedElectrodes(iSelElec);
end


%% ===== EDIT ELECTRODE COLOR =====
function EditElectrodeColor(newColor)
    % Get selected electrode
    [sSelElec, iSelElec] = GetSelectedElectrodes();
    if isempty(iSelElec)
        java_dialog('warning', 'No electrode selected.', 'Edit electrode color');
        return
    end
    % If color is not specified in argument : ask it to user
    if (nargin < 1)
        % Use previous electrode color
        newColor = uisetcolor(sSelElec(1).Color, 'Select electrode color');
        % If no color was selected: exit
        if (length(newColor) ~= 3) || all(sSelElec(1).Color == newColor)
            return
        end
    end
    % Update electrode color
    for i = 1:length(sSelElec)
        sSelElec(i).Color = newColor;
    end
    % Save electrodes
    SetElectrodes(iSelElec, sSelElec);
    % Update electrodes list
    UpdateElecList();
    % Select again electrode
    SetSelectedElectrodes(iSelElec);
end


%% ===== VALIDATE OPTIONS =====
function ValidateOptions(optName, jControl)
    % Get figure controls
    ctrl = bst_get('PanelControls', 'iEEG');
    if isempty(ctrl) || isempty(ctrl.jListElec)
        return
    end
    % Get all electrodes
    sElectrodes = GetElectrodes();
    if isempty(sElectrodes)
        return
    end
    % Get the previously selected electrodes (otherwise it updates the newly selected electrode)
    iSelElec = str2num(ctrl.jLabelSelectElec.getText());
    if isempty(iSelElec)
        return;
    end
    sSelElec = sElectrodes(iSelElec);
    % Get new value
    if strcmpi(optName, 'Type')
        val = char(jControl.getText());
    elseif strcmpi(optName, 'ContactNumber')
        val = str2num(jControl.getText());
    else
        val = str2num(jControl.getText()) / 1000;
    end
    % If setting multiple contacts: do not accept [] as a valid entry
    if isempty(val) && (length(sSelElec) > 1)
        return;
    end
    % Update field for all the selected electrodes
    isModified = 0;
    for i = 1:length(sSelElec)
        if ~isequal(sSelElec(i).(optName), val)
            sSelElec(i).(optName) = val;
            isModified = 1;
        end
    end
    % Save electrodes
    if isModified
        SetElectrodes(iSelElec, sSelElec);
    end
end
    

%% ===== SHOW/HIDE ELECTRODE =====
function SetElectrodeVisible(isVisible)
    % Get selected electrode
    [sSelElec, iSelElec] = GetSelectedElectrodes();
    if isempty(iSelElec)
        java_dialog('warning', 'No electrode selected.', 'Show/hide electrode');
        return
    end
    % Update electrode color
    for i = 1:length(sSelElec)
        sSelElec(i).Visible = isVisible;
    end
    % Save electrodes
    SetElectrodes(iSelElec, sSelElec);
    % Update electrodes list
    UpdateElecList();
    % Select again electrode
    SetSelectedElectrodes(iSelElec);
end
    

%% ===== GET ELECTRODES =====
function [sElectrodes, iDS, iFig, hFig] = GetElectrodes()
    global GlobalData;
    % Get current figure
    [hFig,iFig,iDS] = bst_figures('GetCurrentFigure');
    % Check if there are electrodes defined for this file
    if isempty(hFig) || isempty(GlobalData.DataSet(iDS).IntraElectrodes)
        sElectrodes = [];
        return;
    end
    % Return all the available electrodes
    sElectrodes = GlobalData.DataSet(iDS).IntraElectrodes;
end


%% ===== SET ELECTRODES =====
% USAGE:  iElec = SetElectrodes(iElec=[], sElect)
%         iElec = SetElectrodes('Add', sElect)
function iElec = SetElectrodes(iElec, sElect)
    global GlobalData;
    % Parse input
    isAdd = ~isempty(iElec) && ischar(iElec) && strcmpi(iElec, 'Add');
    % Get dataset
    [sElecOld, iDS] = GetElectrodes();
    % If there is no selected dataset
    if isempty(iDS)
        return;
    end
    % Replace all the electrodes
    if isempty(iElec) || isempty(GlobalData.DataSet(iDS).IntraElectrodes)
        GlobalData.DataSet(iDS).IntraElectrodes = sElecOld;
        iElec = 1:length(sElect);
    % Set specific electrodes
    else
        % Add new electrode
        if isAdd
            iElec = length(GlobalData.DataSet(iDS).IntraElectrodes) + (1:length(sElect));
            % Make new electrode names unique
            if ~isempty(GlobalData.DataSet(iDS).IntraElectrodes)
                for i = 1:length(sElect)
                    sElect(i).Name = file_unique(sElect(i).Name, {GlobalData.DataSet(iDS).IntraElectrodes.Name, sElect(1:i-1).Name});
                end
            end
        end
        % Set electrode in global structure
        if isempty(sElect)
            GlobalData.DataSet(iDS).IntraElectrodes(iElec) = [];
        else
            GlobalData.DataSet(iDS).IntraElectrodes(iElec) = sElect;
        end
    end
    % Add color if not defined yet
    for i = 1:length(GlobalData.DataSet(iDS).IntraElectrodes)
        if isempty(GlobalData.DataSet(iDS).IntraElectrodes(i).Color)
            ColorTable = GetElectrodeColorTable();
            iColor = mod(i-1, length(ColorTable)) + 1;
            GlobalData.DataSet(iDS).IntraElectrodes(i).Color = ColorTable(iColor,:);
        end
    end
    % Mark channel file as modified
    GlobalData.DataSet(iDS).isChannelModified = 1;
    % Update all the displays
    UpdateFigures();
end


%% ===== ADD ELECTRODE =====
function AddElectrode()
    global GlobalData;
    % Get available electrodes
    [sAllElec, iDS, iFig] = GetElectrodes();
    % Get modality
    if ~isempty(iFig)
        Modality = GlobalData.DataSet(iDS).Figure(iFig).Id.Modality;
    else
        Modality = 'SEEG';
    end
    % Ask user for a new label
    res = java_dialog('input', {'Electrode label:', 'Modality (SEEG or ECOG):'}, 'Add electrode', [], {'',Modality});
    if isempty(res) || (length(res) < 2) || isempty(res{1})
        return;
    end
    newLabel = res{1};
    newModality = res{2};
    % Check if label already exists
    if any(strcmpi({sAllElec.Name}, newLabel))
        java_dialog('warning', ['Electrode "' newLabel '" already exists.'], 'New electrode');
        return;
    end
    % Check modality
    if isempty(newModality) || ~ismember(newModality, {'SEEG','ECOG','EEG'})
        java_dialog('warning', ['Invalid modality "' newModality '".'], 'New electrode');
        return;
    end
    % Create new electrode structure
    sElect = db_template('intraelectrode');
    sElect.Name = newLabel;
    sElect.Type = newModality;
    % Add new electrode
    iElec = SetElectrodes('Add', sElect);
    % Update JList
    UpdateElecList();
    % Select again electrode
    SetSelectedElectrodes(iElec);
end

%% ===== REMOVE ELECTRODE =====
function RemoveElectrode()
    global GlobalData;
    % Get dataset
    [sElecOld, iDS] = GetElectrodes();
    if isempty(iDS)
        return;
    end
    % Get selected electrode
    [sSelElec, iSelElec] = GetSelectedElectrodes();
    if isempty(iSelElec)
        java_dialog('warning', 'No electrode selected.', 'Remove color');
        return
    end
    % Ask for confirmation
    if (length(sSelElec) == 1)
        strConfirm = ['Delete electrode "' sSelElec.Name '"?'];
    else
        strConfirm = ['Delete ' num2str(length(sSelElec)) ' electrodes?'];
    end
    if ~java_dialog('confirm', strConfirm)
        return;
    end
    % Delete electrodes
    GlobalData.DataSet(iDS).IntraElectrodes(iSelElec) = [];
    % Update list of electrodes
    UpdateElecList();
end


%% ===== GET ELECTRODE MODELS =====
function sModels = GetElectrodeModels()
    global GlobalData;
    % Get existing preferences
    if isfield(GlobalData, 'Preferences') && isfield(GlobalData.Preferences, 'IntraElectrodeModels') && ~isempty(GlobalData.Preferences.IntraElectrodeModels)
        sModels = GlobalData.Preferences.IntraElectrodeModels;
    % Get default list of known electrodes
    else
        % === DIXI D08 ===
        % Common values
        sTemplate = db_template('intraelectrode');
        sTemplate.Type = 'SEEG';
        sTemplate.ContactSpacing  = 0.0035;
        sTemplate.ContactDiameter = 0.0008;
        sTemplate.ContactLength   = 0.002;
        sTemplate.ElecDiameter    = 0.0007;
        sTemplate.ElecLength      = 0.070;
        % All models
        sModels = repmat(sTemplate, 1, 6);
        sModels(1).Model         = 'DIXI D08-05AM Microdeep';
        sModels(1).ContactNumber = 5;
        sModels(2).Model         = 'DIXI D08-08AM Microdeep';
        sModels(2).ContactNumber = 8;
        sModels(3).Model         = 'DIXI D08-10AM Microdeep';
        sModels(3).ContactNumber = 10;
        sModels(4).Model         = 'DIXI D08-12AM Microdeep';
        sModels(4).ContactNumber = 12;
        sModels(5).Model         = 'DIXI D08-15AM Microdeep';
        sModels(5).ContactNumber = 15;
        sModels(6).Model         = 'DIXI D08-18AM Microdeep';
        sModels(6).ContactNumber = 18;
    end
end


%% ===== GET SELECTED MODEL =====
function [iModel, sModels] = GetSelectedModel()
    % Get figure controls
    ctrl = bst_get('PanelControls', 'iEEG');
    if isempty(ctrl) || isempty(ctrl.jListElec)
        return
    end
    % Get the available electrode models
    sModels = GetElectrodeModels();
    % Get selected model
    ModelName = char(ctrl.jComboModel.getSelectedItem());
    if isempty(ModelName)
        iModel = [];
    else
        iModel = find(strcmpi({sModels.Model}, ModelName));
    end
end


%% ===== SET SELECTED MODEL =====
function SetSelectedModel(selModel)
    % Get figure controls
    ctrl = bst_get('PanelControls', 'iEEG');
    if isempty(ctrl) || isempty(ctrl.jListElec)
        return
    end
    % Find model list in the combo box
    iModel = 0;
    for i = 1:ctrl.jComboModel.getItemCount()
        if strcmpi(selModel, ctrl.jComboModel.getItemAt(i))
            iModel = i;
            break;
        end
    end
    % Save combobox callback
    jModel = ctrl.jComboModel.getModel();
    bakCallback = java_getcb(jModel, 'ContentsChangedCallback');
    java_setcb(jModel, 'ContentsChangedCallback', []);
    % Select model
    ctrl.jComboModel.setSelectedIndex(iModel);
    % Restore callback
    java_setcb(jModel, 'ContentsChangedCallback', bakCallback);
end

%% ===== ADD ELECTRODE MODEL =====
function AddElectrodeModel()
    global GlobalData;
    % Get figure controls
    ctrl = bst_get('PanelControls', 'iEEG');
    if isempty(ctrl) || isempty(ctrl.jListElec)
        return
    end
    % === ECOG ===
    if ctrl.jRadioEcog.isSelected()
        % Ask for all the elecgtrode options
        res = java_dialog('input', {...
            'Manufacturer and model (ECOG):', ...
            'Number of contacts:', ...
            'Contact spacing (mm):', ...
            'Contact height (mm):', ...
            'Contact diameter (mm):', ...
            'Wire width (points):'}, 'Add new model', [], ...
            {'', '', '3.5', '0.8', '2', '0.5'});
        if isempty(res) || isempty(res{1})
            return;
        end
        % Get all the values
        sNew = db_template('intraelectrode');
        sNew.Type            = 'ECOG';
        sNew.Model           = res{1};
        sNew.ContactNumber   = str2num(res{2});
        sNew.ContactSpacing  = str2num(res{3}) ./ 1000;
        sNew.ContactLength   = str2num(res{4}) ./ 1000;
        sNew.ContactDiameter = str2num(res{5}) ./ 1000;
        sNew.ElecDiameter    = str2num(res{6}) ./ 1000;
        sNew.ElecLength      = 0;
    % === SEEG ===
    else
        % Ask for all the elecgtrode options
        res = java_dialog('input', {...
            'Manufacturer and model (SEEG):', ...
            'Number of contacts:', ...
            'Contact spacing (mm):', ...
            'Contact length (mm):', ...
            'Contact diameter (mm):', ...
            'Electrode diameter (mm):', ...
            'Electrode length (mm):'}, 'Add new model', [], ...
            {'', '', '3.5', '2', '0.8', '0.7', '70'});
        if isempty(res) || isempty(res{1})
            return;
        end
        % Get all the values
        sNew = db_template('intraelectrode');
        sNew.Model           = res{1};
        sNew.Type            = 'SEEG';
        sNew.ContactNumber   = str2num(res{2});
        sNew.ContactSpacing  = str2num(res{3}) ./ 1000;
        sNew.ContactLength   = str2num(res{4}) ./ 1000;
        sNew.ContactDiameter = str2num(res{5}) ./ 1000;
        sNew.ElecDiameter    = str2num(res{6}) ./ 1000;
        sNew.ElecLength      = str2num(res{7}) ./ 1000;
    end
    % Get available models
    sModels = GetElectrodeModels();
    % Check that the electrode model is unique
    if any(strcmpi({sModels.Model}, sNew.Model))
        bst_error(['Electrode model "' sNew.Model '" is already defined.'], 'Add new model', 0);
        return;
    % Check that all the values are set
    elseif isempty(sNew.ContactNumber) || isempty(sNew.ContactSpacing) || isempty(sNew.ContactDiameter) || isempty(sNew.ContactLength) || isempty(sNew.ElecDiameter) || isempty(sNew.ElecLength)
        bst_error('Invalid values.', 'Add new model', 0);
        return;
    end
    % Add new electrode
    sModels(end+1) = sNew;
    GlobalData.Preferences.IntraElectrodeModels = sModels;
    % Update list of models
    UpdateElecProperties();
end


%% ===== REMOVE ELECTRODE MODEL =====
function RemoveElectrodeModel()
    global GlobalData;
    % Get panel controls
    ctrl = bst_get('PanelControls', 'iEEG');
    if isempty(ctrl) || isempty(ctrl.jListElec)
        return
    end
    % Get selected model
    [iModel, sModels] = GetSelectedModel();
    if isempty(iModel)            
        return;
    end
    % Ask for confirmation
    if ~java_dialog('confirm', ['Delete model "' sModels(iModel).Model '"?'])
        return;
    end
    % Delete model
    sModels(iModel) = [];
    GlobalData.Preferences.IntraElectrodeModels = sModels;
    % Update list of models
    UpdateElecProperties();
end


%% ===== UPDATE FIGURES =====
function UpdateFigures(hFigTarget)
    global GlobalData;
    % Parse inputs
    if (nargin < 1) || isempty(hFigTarget)
        hFigTarget = [];
    end
    % Get loaded dataset
    [sElectrodes, iDS] = GetElectrodes();
    if isempty(iDS) || isempty(GlobalData.DataSet(iDS).ChannelFile)
        return;
    end
    % Get channel file
    ChannelFile = GlobalData.DataSet(iDS).ChannelFile;
    % Progress bar
    isProgress = bst_progress('isVisible');
    if ~isProgress
        bst_progress('start', 'iEEG', 'Updating display...');
    end
    % Update all the figures that share this channel file
    for iDS = 1:length(GlobalData.DataSet)
        % Skip if not the correct channel file
        if ~file_compare(GlobalData.DataSet(iDS).ChannelFile, ChannelFile)
            continue;
        end
        % Update all the figures in this dataset
        for iFig = 1:length(GlobalData.DataSet(iDS).Figure)
            Figure = GlobalData.DataSet(iDS).Figure(iFig);
            % If there is one target figure to update only:
            if ~isempty(hFigTarget) && ~isequal(hFigTarget, Figure.hFigure)
                continue;
            end
            % Update figure
            switch (Figure.Id.Type)
                case 'Topography'
                    bst_figures('ReloadFigures', Figure.hFigure, 0);
                case '3DViz'
                    hElectrodeObjects = [findobj(Figure.hFigure, 'Tag', 'ElectrodeGrid'); findobj(Figure.hFigure, 'Tag', 'ElectrodeDepth'); findobj(Figure.hFigure, 'Tag', 'ElectrodeWire')];
                    if ~isempty(hElectrodeObjects)
                        figure_3d('PlotSensors3D', iDS, iFig);
                    end
                case 'MriViewer'
                    hElectrodeObjects = [findobj(Figure.hFigure, 'Tag', 'ElectrodeGrid'); findobj(Figure.hFigure, 'Tag', 'ElectrodeDepth'); findobj(Figure.hFigure, 'Tag', 'ElectrodeWire')];
                    if ~isempty(hElectrodeObjects)
                        figure_mri('PlotSensors3D', iDS, iFig);
                        GlobalData.DataSet(iDS).Figure(iFig).Handles = figure_mri('PlotElectrodes', iDS, iFig, GlobalData.DataSet(iDS).Figure(iFig).Handles);
                        figure_mri('UpdateVisibleSensors3D', Figure.hFigure);
                        figure_mri('UpdateVisibleLandmarks', Figure.hFigure);
                    end
            end
        end
    end
    % Close progress bar
    if ~isProgress
        bst_progress('stop');
    end
end


%% ===== SET DISPLAY MODE =====
function SetDisplayMode(DisplayMode)
    % Get current figure
    [sElectrodes, iDS, iFig, hFig] = GetElectrodes();
    if isempty(hFig)
        return;
    end
    % Update display mode
    getappdata(hFig, 'ElectrodeDisplay');
    ElectrodeDisplay.DisplayMode = DisplayMode;
    setappdata(hFig, 'ElectrodeDisplay', ElectrodeDisplay);
    % Update figures
    UpdateFigures(hFig);
end


%% ===== DETECT ELETRODES =====
function [ChannelMat, ChanOrient, ChanLocFix] = DetectElectrodes(ChannelMat, Modality, AllInd)
    % Get channels for modality
    iMod = good_channel(ChannelMat.Channel, [], Modality);
    if isempty(iMod)
        ChanOrient = [];
        ChanLocFix = [];
        return;
    end
    % Returned variables
    ChanOrient = zeros(length(ChannelMat.Channel),3);
    ChanLocFix = zeros(length(ChannelMat.Channel),3);
    % Contact indices missing, detecting them
    if (nargin < 3) || isempty(AllInd)
        [AllGroups, AllTags, AllInd, isNoInd] = panel_montage('ParseSensorNames', ChannelMat.Channel(iMod));
    end
    % Add IntraElectrodes field if not present
    if ~isfield(ChannelMat, 'IntraElectrodes') || isempty(ChannelMat.IntraElectrodes)
        ChannelMat.IntraElectrodes = repmat(db_template('intraelectrode'), 0);
    end
    % Get color table
    ColorTable = GetElectrodeColorTable();
    % Get all groups
    uniqueGroups = unique({ChannelMat.Channel(iMod).Group});
    for iGroup = 1:length(uniqueGroups)
        % If electrode already exists (or no group): skip
        if any(strcmpi({ChannelMat.IntraElectrodes.Name}, uniqueGroups{iGroup})) || isempty(uniqueGroups{iGroup})
            continue;
        end
        % Get electrodes in group
        iGroupChan = find(strcmpi({ChannelMat.Channel(iMod).Group}, uniqueGroups{iGroup}));
        % Sort electrodes by index number
        [IndMod, I] = sort(AllInd(iGroupChan));
        iGroupChan = iGroupChan(I);
        % Create electrode structure
        newElec = db_template('intraelectrode');
        newElec.Name          = uniqueGroups{iGroup};
        newElec.Type          = Modality;
        newElec.Model         = '';
        newElec.ContactNumber = max(AllInd(iGroupChan));
        newElec.Visible       = 1;
        % Default display options
        ElectrodeConfig = bst_get('ElectrodeConfig', Modality);
        newElec.ContactDiameter = ElectrodeConfig.ContactDiameter;
        newElec.ContactLength   = ElectrodeConfig.ContactLength;
        newElec.ElecDiameter    = ElectrodeConfig.ElecDiameter;
        newElec.ElecLength      = ElectrodeConfig.ElecLength;
        % Default color
        iColor = mod(iGroup-1, length(ColorTable)) + 1;
        newElec.Color = ColorTable(iColor,:);
        % Try to get positions of the electrode: 2 contacts minimum with positions
        if strcmpi(Modality, 'SEEG') && (length(iGroupChan) >= 2) && all(cellfun(@(c)size(c,2), {ChannelMat.Channel(iMod(iGroupChan)).Loc}) == 1)
            % Get all channels locations for this electrode
            ElecLoc = [ChannelMat.Channel(iMod(iGroupChan)).Loc]';
            % Get distance between available contacts (in number of contacts)
            nDist = diff(AllInd(iGroupChan));
            % Detect average spacing between contacts
            newElec.ContactSpacing = mean(sqrt(sum((ElecLoc(1:end-1,:) - ElecLoc(2:end,:)) .^ 2, 2)) ./ nDist(:), 1);

            % Center of the electrodes
            M = mean(ElecLoc);
            % Get the principal orientation between all the vertices
            W = bst_bsxfun(@minus, ElecLoc, M);
            [U,D,V] = svd(W' * W);
            orient = U(:,1)';
            % Orient the direction vector in the correct direction (from the tip to the handle of the strip)
            if (sum(orient .* (M - ElecLoc(1,:))) < 0)
                orient = -orient;
            end
            % Project the electrodes on the line passing through M with orientation "orient"
            ElecLocFix = sum(bst_bsxfun(@times, W, orient), 2);
            ElecLocFix = bst_bsxfun(@times, ElecLocFix, orient);
            ElecLocFix = bst_bsxfun(@plus, ElecLocFix, M);

            % Set tip: Compute the position of the first contact
            newElec.Loc(:,1) = (ElecLocFix(1,:) - (AllInd(1) - 1) * newElec.ContactSpacing * orient)';
            % Set entry point: last contact is good enough
            newElec.Loc(:,2) = ElecLocFix(end,:)';

            % Duplicate to set orientation and fixed position for all the channels of the strip
            ChanOrient(iMod(iGroupChan),:) = repmat(orient, length(iGroupChan), 1);
            ChanLocFix(iMod(iGroupChan),:) = ElecLocFix;
        end
        % Add to existing list of electrodes
        if ~isfield(ChannelMat, 'IntraElectrodes') || isempty(ChannelMat.IntraElectrodes)
            ChannelMat.IntraElectrodes = newElec;
        else
            ChannelMat.IntraElectrodes(end+1) = newElec;
        end
    end
end

    
                              
%% =================================================================================
%  === DISPLAY ELECTRODES  =========================================================
%  =================================================================================

%% ===== CREATE 3D ELECTRODE GEOMETRY =====
function [ElectrodeDepth, ElectrodeLabel, ElectrodeWire, ElectrodeGrid] = CreateGeometry3DElectrode(iDS, iFig, Channel, ChanLoc) %#ok<DEFNU>
    global GlobalData;
    % Initialize returned values
    ElectrodeDepth = [];
    ElectrodeLabel = [];
    ElectrodeWire  = [];
    ElectrodeGrid  = [];
    % Get subject
    sSubject = bst_get('Subject', GlobalData.DataSet(iDS).SubjectFile);
    isSurface = ~isempty(sSubject) && (~isempty(sSubject.iInnerSkull) || ~isempty(sSubject.iScalp) || ~isempty(sSubject.iCortex));
    % Get figure and modality
    hFig = GlobalData.DataSet(iDS).Figure(iFig).hFigure;
    Modality = GlobalData.DataSet(iDS).Figure(iFig).Id.Modality;

    % ===== CONTACTS GEOMETRY =====
    % SEEG contact cylinder
    nVert = 34;
    [seegVertex, seegFaces] = tess_cylinder(nVert, 0.5);
    % ECOG contact cylinder: Define electrode geometry (double-layer for Matlab < 2014b)
    if (bst_get('MatlabVersion') < 804)
        nVert = 66;
        [ecogVertex, ecogFaces] = tess_cylinder(nVert, 0.8, [], [], 1);
    else
        nVert = 34;
        [ecogVertex, ecogFaces] = tess_cylinder(nVert, 0.8, [], [], 0);
    end
    % Define electrode geometry
    nVert = 32;
    [sphereVertex, sphereFaces] = tess_sphere(nVert);
    % Get display configuration from iEEG tab
    ElectrodeDisplay = getappdata(hFig, 'ElectrodeDisplay');
    % Optimal lighting depends on Matlab version
    if (bst_get('MatlabVersion') < 804)
        FaceLighting = 'gouraud';
    else
        FaceLighting = 'flat';
    end
    % Compute contact normals: ECOG and EEG
    if isSurface && (ismember(Modality, {'ECOG','EEG'}) || (~isempty(GlobalData.DataSet(iDS).IntraElectrodes) && any(strcmpi({GlobalData.DataSet(iDS).IntraElectrodes.Type}, 'ECOG'))))
        ChanNormal = GetChannelNormal(sSubject, ChanLoc, Modality);
    end
    
    % ===== DISPLAY SEEG/ECOG ELECTRODES =====
    iChanProcessed = [];
    UserData    = [];
    Vertex      = [];
    Faces       = [];
    VertexAlpha = [];
    VertexRGB   = [];
    ctVertex    = [];
    % Get electrode configuration
    if ~isempty(GlobalData.DataSet(iDS).IntraElectrodes)
        % Get electrode groups
        [iEeg, GroupNames] = panel_montage('GetEegGroups', Channel, [], 1);
        % Display the electrodes one by one
        for iElec = 1:length(GlobalData.DataSet(iDS).IntraElectrodes)
            sElec = GlobalData.DataSet(iDS).IntraElectrodes(iElec);
            % Get contacts for this electrode
            iGroup = find(strcmpi(sElec.Name, GroupNames));
            % If there are contacts to plot
            if ~isempty(iGroup)
                iElecChan = iEeg{iGroup};
            else
                iElecChan = [];
            end
            % Hide/show
            if sElec.Visible
                elecAlpha = 1;
            else
                elecAlpha = 0;
            end
            
            % === SPHERE ===
            if (strcmpi(ElectrodeDisplay.DisplayMode, 'sphere') || (strcmpi(sElec.Type, 'ECOG') && ~isSurface)) && ~isempty(sElec.ContactDiameter) && (sElec.ContactDiameter > 0) && ~isempty(sElec.ContactLength) && (sElec.ContactLength > 0)
                % Contact size and orientation
                if strcmpi(sElec.Type, 'SEEG')
                    ctSize = [1 1 1] .* sElec.ContactLength;
                else
                    ctSize = [1 1 1] .* sElec.ContactDiameter ./ 2;
                end
                ctOrient = [];
                ctColor  = sElec.Color;
                % Create contacts geometry
                [ctVertex, ctFaces] = Plot3DContacts(sphereVertex, sphereFaces, ctSize, ChanLoc(iElecChan,:), ctOrient);
                % Force Gouraud lighting
                FaceLighting = 'gouraud';
                
            % === SEEG ===
            elseif strcmpi(sElec.Type, 'SEEG')
                % If no location available: cannot display
                if (size(sElec.Loc,2) < 2)
                    continue;
                end
                % Electrode orientation
                elecOrient = sElec.Loc(:,end)' - sElec.Loc(:,1)';
                elecOrient = elecOrient ./ sqrt(sum((elecOrient).^2));
                % Plot depth electrode
                if sElec.Visible && ~isempty(sElec.ElecDiameter) && (sElec.ElecDiameter > 0) && ~isempty(sElec.ElecLength) && (sElec.ElecLength > 0) && ~isempty(sElec.Color)
                    % Create cylinder
                    elecSize   = [sElec.ElecDiameter ./ 2, sElec.ElecDiameter ./ 2, sElec.ElecLength];
                    elecSize   = elecSize - 0.00002;  % Make it slightly smaller than the contacts, so it doesn't cover them when they are the same size
                    elecStart  = sElec.Loc(:,1)';
                    nVert      = 24;
                    [elecVertex, elecFaces] = tess_cylinder(nVert, 1, elecSize, elecOrient);
                    % Set electrode actual position
                    elecVertex = bst_bsxfun(@plus, elecVertex, elecStart);
                    % Electrode object
                    iElec = length(ElectrodeDepth) + 1;
                    ElectrodeDepth(iElec).Faces     = elecFaces;
                    ElectrodeDepth(iElec).Vertices  = elecVertex;
                    ElectrodeDepth(iElec).FaceColor = sElec.Color;
                    ElectrodeDepth(iElec).FaceAlpha = elecAlpha;
                    ElectrodeDepth(iElec).Options = {...
                        'EdgeColor',        'none', ...
                        'BackfaceLighting', 'unlit', ...
                        'AmbientStrength',  0.5, ...
                        'DiffuseStrength',  0.5, ...
                        'SpecularStrength', 0.2, ...
                        'SpecularExponent', 1, ...
                        'SpecularColorReflectance', 0, ...
                        'FaceLighting',     'gouraud', ...
                        'EdgeLighting',     'gouraud', ...
                        'Tag',              'ElectrodeDepth', ...
                        'UserData',         sElec.Name};
                    % Add text at the tip of the electrode
                    locLabel = sElec.Loc(:,1)' + elecOrient * (sElec.ElecLength + 0.005);
                    ElectrodeLabel(iElec).Loc   = locLabel;
                    ElectrodeLabel(iElec).Name  = sElec.Name;
                    ElectrodeLabel(iElec).Color = sElec.Color;
                    ElectrodeLabel(iElec).Options = {...
                        'FontUnits',   'points', ...
                        'Tag',         'ElectrodeLabel', ...
                        'Interpreter', 'none', ...
                        'UserData',    sElec.Name};
                end
                % Plot contacts
                if ~isempty(iElecChan) && ~isempty(sElec.ContactDiameter) && (sElec.ContactDiameter > 0) && ~isempty(sElec.ContactLength) && (sElec.ContactLength > 0)
                    % Contact size and orientation
                    ctSize   = [sElec.ContactDiameter ./ 2, sElec.ContactDiameter ./ 2, sElec.ContactLength];
                    ctOrient = repmat(elecOrient, length(iElecChan), 1);
                    ctColor  = [.9,.9,0];
                    % Create contacts geometry
                    [ctVertex, ctFaces] = Plot3DContacts(seegVertex, seegFaces, ctSize, ChanLoc(iElecChan,:), ctOrient);
                end
                
            % === ECOG ===
            elseif strcmpi(sElec.Type, 'ECOG')
                % Display ECOG wires
                if sElec.Visible && (length(iElecChan) >= 2) && ~isempty(sElec.ElecDiameter) && (sElec.ElecDiameter > 0)
                    % Check if all the contacts are aligned
                    isAligned = 1;
                    for i = 2:(length(iElecChan)-1)
                        % Calculate dot product of vectors (i-1,i) and (i,i+1)
                        d = sum((ChanLoc(iElecChan(i),:) - ChanLoc(iElecChan(i-1),:)) .* (ChanLoc(iElecChan(i+1),:) - ChanLoc(iElecChan(i),:)));
                        % If negative skip this group
                        if (d < 0)
                            isAligned = 0;
                            break;
                        end
                    end
                    % Plot wire
                    if isAligned
                        iElec = length(ElectrodeWire) + 1;
                        ElectrodeWire(iElec).Loc = ChanLoc(iElecChan,:);
                        ElectrodeWire(iElec).LineWidth = sElec.ElecDiameter * 1000;
                        ElectrodeWire(iElec).Color     = sElec.Color;
                        ElectrodeWire(iElec).Options = {...
                            'LineStyle', '-', ...
                            'Tag',       'ElectrodeWire', ...
                            'UserData',  sElec.Name};
                    end
                    % Add text on top of the 1st contact
                    locLabel = 1.1 * ChanLoc(iElecChan(1),:);
                    iElec = length(ElectrodeLabel) + 1;
                    ElectrodeLabel(iElec).Loc     = locLabel;
                    ElectrodeLabel(iElec).Name    = sElec.Name;
                    ElectrodeLabel(iElec).Color   = sElec.Color;
                    ElectrodeLabel(iElec).Options = {...
                        'FontUnits',   'points', ...
                        'Tag',         'ElectrodeLabel', ...
                        'Interpreter', 'none', ...
                        'UserData',    sElec.Name};
                end
                % Plot contacts
                if ~isempty(iElecChan) && ~isempty(sElec.ContactDiameter) && (sElec.ContactDiameter > 0) && ~isempty(sElec.ContactLength) && (sElec.ContactLength > 0)
                    % Contact size and orientation
                    ctSize   = [sElec.ContactDiameter ./ 2, sElec.ContactDiameter ./ 2, sElec.ContactLength];
                    ctOrient = ChanNormal(iElecChan,:);
                    ctColor  = [.9,.9,0];
                    % Create contacts geometry
                    [ctVertex, ctFaces] = Plot3DContacts(ecogVertex, ecogFaces, ctSize, ChanLoc(iElecChan,:), ctOrient);
                end
            end
            % If there are contacts to render
            if ~isempty(iElecChan) && ~isempty(ctVertex)
                % Add to global patch
                offsetVert  = size(Vertex,1);
                Vertex      = [Vertex;      ctVertex];
                Faces       = [Faces;       ctFaces + offsetVert];
                VertexAlpha = [VertexAlpha; repmat(elecAlpha, size(ctVertex,1), 1)];
                VertexRGB   = [VertexRGB;   repmat(ctColor,   size(ctVertex,1), 1)];
                % Save the channel index in the UserData
                UserData    = [UserData;    reshape(repmat(iElecChan, size(ctVertex,1)./length(iElecChan), 1), [], 1)];
                % Add to the list of processed channels
                iChanProcessed = [iChanProcessed, iElecChan];
            end
        end
    end
    
    % ===== ADD SPHERE CONTACTS ======
    % Get the sensors that haven't been displayed yet
    iChanOther = setdiff(1:length(Channel), iChanProcessed);
    % Display spheres
    if ~isempty(iChanOther)
        % Get the saved display defaults for this modality
        ElectrodeConfig = bst_get('ElectrodeConfig', Modality);
        % SEEG: Sphere
        if strcmpi(Modality, 'SEEG')
            ctSize    = [1 1 1] .* ElectrodeConfig.ContactLength ./ 2;
            tmpVertex = sphereVertex;
            tmpFaces  = sphereFaces;
            ctOrient  = [];
            % Force Gouraud lighting
            FaceLighting = 'gouraud';
        % ECOG/EEG: Cylinder
        else
            ctSize   = [ElectrodeConfig.ContactDiameter ./ 2, ElectrodeConfig.ContactDiameter ./ 2, ElectrodeConfig.ContactLength];
            ctOrient = ChanNormal(iChanOther,:);
            tmpVertex = ecogVertex;
            tmpFaces  = ecogFaces;
        end
        % Create contacts geometry
        [ctVertex, ctFaces] = Plot3DContacts(tmpVertex, tmpFaces, ctSize, ChanLoc(iChanOther,:), ctOrient);
        % Display properties
        ctColor   = [.9,.9,0];
        elecAlpha = 1;
        % Add to global patch
        offsetVert  = size(Vertex,1);
        Vertex      = [Vertex;      ctVertex];
        Faces       = [Faces;       ctFaces + offsetVert];
        VertexAlpha = [VertexAlpha; repmat(elecAlpha, size(ctVertex,1), 1)];
        VertexRGB   = [VertexRGB;   repmat(ctColor,   size(ctVertex,1), 1)];
        % Save the channel index in the UserData
        UserData    = [UserData;    reshape(repmat(iChanOther, size(ctVertex,1)./length(iChanOther), 1), [], 1)];
    end
    % Create patch
    ElectrodeGrid.Faces               = Faces;
    ElectrodeGrid.Vertices            = Vertex;
    ElectrodeGrid.FaceVertexCData     = VertexRGB;
    ElectrodeGrid.FaceVertexAlphaData = VertexAlpha;
    ElectrodeGrid.Options = {...
        'EdgeColor',        'none', ...
        'BackfaceLighting', 'unlit', ...
        'AmbientStrength',  0.5, ...
        'DiffuseStrength',  0.6, ...
        'SpecularStrength', 0, ...
        'FaceLighting',     FaceLighting, ...
        'Tag',              'ElectrodeGrid', ...
        'UserData',         UserData};
end

%% ===== PLOT 3D CONTACTS =====
function [Vertex, Faces] = Plot3DContacts(ctVertex, ctFaces, ctSize, ChanLoc, ChanOrient)
    % Apply contact size
    ctVertex = bst_bsxfun(@times, ctVertex, ctSize);
    % Duplicate this contact
    nChan  = size(ChanLoc,1);
    nVert  = size(ctVertex,1);
    nFace  = size(ctFaces,1);
    Vertex = zeros(nChan*nVert, 3);
    Faces  = zeros(nChan*nFace, 3);
    for iChan = 1:nChan
        % Apply orientation
        if ~isempty(ChanOrient) && ~isequal(ChanOrient(iChan,:), [0 0 1])
            v1 = [0;0;1];
            v2 = ChanOrient(iChan,:)';
            % Rotation matrix (Rodrigues formula)
            angle = acos(v1'*v2);
            axis  = cross(v1,v2) / norm(cross(v1,v2));
            axis_skewed = [ 0 -axis(3) axis(2) ; axis(3) 0 -axis(1) ; -axis(2) axis(1) 0];
            R = eye(3) + sin(angle)*axis_skewed + (1-cos(angle))*axis_skewed*axis_skewed;
            % Apply rotation to the vertices of the electrode
            ctVertexOrient = ctVertex * R';
        else
            ctVertexOrient = ctVertex;
        end
        % Set electrode position
        ctVertexOrient = bst_bsxfun(@plus, ChanLoc(iChan,:), ctVertexOrient);
        % Report in final patch
        iVert  = (iChan-1) * nVert + (1:nVert);
        iFace = (iChan-1) * nFace + (1:nFace);
        Vertex(iVert,:) = ctVertexOrient;
        Faces(iFace,:)  = ctFaces + nVert*(iChan-1);
    end
end


%% ===== GET CHANNEL NORMALS =====
function [ChanOrient, ChanLocProj] = GetChannelNormal(sSubject, ChanLoc, Modality)
    % Default modality: ECOG
    if (nargin < 3) || isempty(Modality)
        Modality = 'ECOG';
    end
    % Get surface
    if strcmpi(Modality, 'EEG') || strcmpi(Modality, 'NIRS')
        if ~isempty(sSubject.iScalp)
            SurfaceFile = sSubject.Surface(sSubject.iScalp).FileName;
            isEnvelope = 0;
        else
            error('No scalp surface for this subject.');
        end
    else
        if ~isempty(sSubject.iInnerSkull)
            SurfaceFile = sSubject.Surface(sSubject.iInnerSkull).FileName;
            isEnvelope = 0;
        elseif ~isempty(sSubject.iScalp)
            SurfaceFile = sSubject.Surface(sSubject.iScalp).FileName;
            isEnvelope = 0;
        elseif ~isempty(sSubject.iCortex)
            SurfaceFile = sSubject.Surface(sSubject.iCortex).FileName;
            isEnvelope = 1;
        else
            error('No inner skull or scalp surface for this subject.');
        end
    end
    % Load surface (or get from memory)
    sSurf = bst_memory('LoadSurface', SurfaceFile);
    % Use all the surface
    if ~isEnvelope
        Vertices = sSurf.Vertices;
        VertNormals = sSurf.VertNormals;
    % Get the envelope only
    else
        disp('BST> Warning: For a better orientation of the ECOG electrodes, please import a head or inner skull surface for this subject.');
        Faces = convhulln(sSurf.Vertices);
        iVertices = unique(Faces(:));
        Vertices = sSurf.Vertices(iVertices, :);
        VertNormals = sSurf.VertNormals(iVertices, :);
    end
    
    % Project electrodes on the surface 
    ChanLocProj = channel_project_scalp(Vertices, ChanLoc);
    % Get the closest vertex for each channel
    iChanVert = bst_nearest(Vertices, ChanLocProj);
    % Get the normals at those points
    ChanOrient = VertNormals(iChanVert, :);
    
% OTHER OPTIONS WITH SPHERICAL HARMONICS, A BIT FASTER, TO BE TESTED
%     % Compute spherical harmonics
%     fvh = hsdig2fv(Vertices, 5, 5/1000, 40*pi/180, 0);
%     VertNormals = tess_normals(fvh.vertices, fvh.faces);
%     % Get the closest vertex for each channel
%     iChanVert = bst_nearest(fvh.vertices, ChanLoc);
%     % Get the normals at those points
%     ChanOrient = VertNormals(iChanVert, :);
end


%% ===== ALIGN CONTACTS =====
function AlignContacts(iDS, iFig, Method)
    global GlobalData;
    % Check if there are channels available
    Channels = GlobalData.DataSet(iDS).Channel;
    if isempty(Channels) || isempty(GlobalData.DataSet(iDS).IntraElectrodes)
        return;
    end
    % Get MRI and figure handles
    hFig = GlobalData.DataSet(iDS).Figure(iFig).hFigure;
    % Get selected electrode
    [sSelElec, iSelElec] = GetSelectedElectrodes();
    if isempty(iSelElec)
        java_dialog('warning', 'No electrode selected.', 'Align contacts');
        return
    end
    % Process all the electrodes
    for iElec = 1:length(sSelElec)
        % Check all the electrodes properties are defined
        if isempty(sSelElec(iElec).ContactSpacing)
            disp(['BST> Warning: Contact spacing is not defined for electrode "' sSelElec(iElec).Name '".']);
            continue;
        elseif isempty(sSelElec(iElec).ContactNumber)
            disp(['BST> Warning: Number of contacts is not defined for electrode "' sSelElec(iElec).Name '".']);
            continue;
        elseif (size(sSelElec(iElec).Loc,2) < 2)
            disp(['BST> Warning: Positions are not defined for electrode "' sSelElec(iElec).Name '".']);
            continue;
        end
        % Get contacts for this electrode
        iChan = find(strcmpi({Channels.Group}, sSelElec(iElec).Name));
        if isempty(iChan)
            disp(['BST> Warning: No contact for electrode "' sSelElec(iElec).Name '".']);
            continue;
        end
        % Parse sensor names
        [AllGroups, AllTags, AllInd, isNoInd] = panel_montage('ParseSensorNames', Channels(iChan));
        % Call the function to align electodes
        Modality = Channels(iChan(1)).Type;
        switch (Modality)
            case 'SEEG'
                % Get electrode orientation
                elecTip = sSelElec(iElec).Loc(:,1);
                orient = (sSelElec(iElec).Loc(:,2) - elecTip);
                orient = orient ./ sqrt(sum(orient .^ 2));
                % Process each contact
                for i = 1:length(iChan)
                    switch (Method)
                        case 'default'
                            % Compute the default position of the contact
                            Channels(iChan(i)).Loc = elecTip + (AllInd(i) - 1) * sSelElec(iElec).ContactSpacing * orient;
                        case 'project'
                            % Project the existing contact on the depth electrode
                            Channels(iChan(i)).Loc = elecTip + sum(orient .* (Channels(iChan(i)).Loc - elecTip)) .* orient;
                    end
                end
            case 'ECOG'
                sSubject = bst_get('Subject', getappdata(hFig, 'SubjectFile'));
                Channels = panel_ieeg('AlignEcogElectrodes', Channels, sSubject, Method);
            otherwise
                error('Unsupported modality.');
        end
        % Mark channel file as modified
        GlobalData.DataSet(iDS).isChannelModified = 1;
    end

    % Update electrode position
    GlobalData.DataSet(iDS).Channel = Channels;
    % Update figures
    UpdateFigures(hFig);
end


%% ===== ALIGN ECOG ELECTRODES =====
% Two different representations for the same grid (U=rows, V=cols)
%                             |              V ->
%    Q ___________ S          |        P ___________ T
%     |__|__|__|__|           |         |__|__|__|__| 
%     |__|__|__|__|   ^       |     U   |__|__|__|__| 
%     |__|__|__|__|   U       |     |   |__|__|__|__| 
%     |__|__|__|__|           |         |__|__|__|__| 
%    T             P          |        S             Q
%         <- V                |
%
function Channels = AlignEcogElectrodes(Channels, sSubject, nCorners)
    % Parse inputs
    if (nargin < 3) || isempty(nCorners)
        nCorners = 2;
    end
    % This can be performed only with the inner skull
    if isempty(sSubject.iInnerSkull) || (sSubject.iInnerSkull > length(sSubject.Surface))
        bst_error('You need to define the inner skull surface of the subject before using this function.', 'Align electrode contacts', 0);
        Channels = [];
        return;
    end
    % Get groups of electrodes
    [iGroupEeg, GroupNames] = panel_montage('GetEegGroups', Channels, [], 1);
    if isempty(iGroupEeg)
        bst_error(['No groups of electrodes are defined. ' 10 'Please edit the channel file and set the Name or Comment fields of the ECOG electrodes.'], 'Align electrode contacts', 0);
        Channels = [];
        return;
    end
    % Select groups of electrodes to align
    SelGroup = java_dialog('combo', 'Select the group of contacts to align:', 'Align electrode contacts', [], GroupNames);
    if isempty(SelGroup)
        Channels = [];
        return;
    end
    % Get electrodes in the selected group
    iSelGroup = find(strcmpi(SelGroup, GroupNames));
    iChan = iGroupEeg{iSelGroup};
    % Default dimensions
    nElec = length(iChan);
    % ECOG strip
    if (nCorners == 1)
        nRows = 1;
        nCols = nElec;
    % ECOG grid
    else
        switch(nElec)
            case 4,    nRows = 1;   nCols = 4;
            case 6,    nRows = 1;   nCols = 6;
            case 8,    nRows = 1;   nCols = 8;
            case 12,   nRows = 2;   nCols = 6;
            case 16,   nRows = 2;   nCols = 8;
            case 32,   nRows = 4;   nCols = 8;
            case 64,   nRows = 8;   nCols = 8;
            otherwise, nRows = 1;   nCols = nElec;
        end
    end
    
    % Ask for number of rows and colums of the grid
    switch (nCorners)
        % Strips: two edges
        case 1
            orient = 0;
        % Grids: two corners
        case 2
            % Get default width for the grid (isotropic scaling)
            P = Channels(iChan(1)).Loc';
            Q = Channels(iChan(end)).Loc';
            PQ = sqrt(sum((Q-P).^2, 2));
            unitX = PQ / sqrt((nCols-1).^2 + (nRows-1).^2);
            % Ask user the confirmation
            res = java_dialog('input', ...
                {['<HTML>Number of contacts in this group: <B>', num2str(nElec), '</B><BR><BR>'...
                  'Number of rows:'], ...
                  'Number of columns:', ...
                  'Space between two rows (mm):', ...
                  '<HTML>Orientation of the grid:<BR>0=Rows first, 1=Columns first'}, 'Define ECOG grid', [], ...
                 {num2str(nRows), num2str(nCols), num2str(unitX * 1000), '0'});
            if isempty(res) || (length(res) < 4) || isnan(str2double(res{1})) || isempty(str2double(res{1})) || isnan(str2double(res{2})) || isempty(str2double(res{2})) || isnan(str2double(res{3})) || isempty(str2double(res{3})) || isnan(str2double(res{4})) || isempty(str2double(res{4}))
                return
            end
            nRows = str2double(res{1});
            nCols = str2double(res{2});
            unitX = str2double(res{3}) / 1000;
            orient = str2double(res{4});
        % Grids: four corners
        case 4
            res = java_dialog('input', ...
                {['<HTML>Number of contacts in this group: <B>', num2str(nElec), '</B><BR><BR>'...
                  'Number of rows:'], 'Number of columns:'}, 'Define ECOG grid', [], ...
                 {num2str(nRows), num2str(nCols)});
            if isempty(res) || (length(res) < 2) || isnan(str2double(res{1})) || isempty(str2double(res{1})) || isnan(str2double(res{2})) || isempty(str2double(res{2}))
                return
            end
            nRows = str2double(res{1});
            nCols = str2double(res{2});
            orient = 0;
    end
    % Check dimensions
    if (nCols*nRows ~= nElec)
        bst_error('The number of contacts of the grid does not match the group defined in the channel file.', 'Align electrode contacts', 0);
        Channels = [];
        return;
    elseif (nCols < 2) || (nRows < 2)
        nCorners = 1;
    end

    % Get the coordinates of the four corners
    P = Channels(iChan(1)).Loc';
    S = Channels(iChan(nRows)).Loc';
    T = Channels(iChan(end-nRows+1)).Loc';
    Q = Channels(iChan(end)).Loc';
    % Project those points on the inner skull
    [EdgeOrient, EdgeLoc] = figure_3d('GetChannelNormal', sSubject, [P;S;T;Q]);
    % Retreive coordinates
    P = EdgeLoc(1,:); 
    S = EdgeLoc(2,:); 
    T = EdgeLoc(3,:); 
    Q = EdgeLoc(4,:); 
    
    % Define all the electrodes
    NewLoc = zeros(nElec, 3);
    % Get the electrodes indices
    [I,J] = meshgrid(1:nRows, 1:nCols);
    % Get list of indices, for the approriate orientation
    switch (orient)
        case 0,    I = I'; J = J'; 
        case 1,    I = I(:);   J = J(:);
        otherwise, error('Unsupported orientation');
    end
    I = I(:);
    J = J(:);

    % Reconstruct grid from different number of points
    switch (nCorners)
        % Strip: two edges
        case 1
            I = (1:nElec)';
            NewLoc = ((nElec-I) * P + (I-1) * Q) ./ (nElec - 1);
            
        % Grids: two corners
        case 2
            % Get the average normal
            GridNormal = (EdgeOrient(1,:) + EdgeOrient(4,:)) ./ 2;
            % Get the distances between P/S   (S = third corner)
            PS = (nRows-1) * unitX;
            % Alpha = angle between PQ and PS
            alpha = acos(PS/PQ);
            % S1=projection of S on PQ;   S2=projection of S on w
            S1 = cos(alpha) * PS;
            S2 = sin(alpha) * PS;
            % Calculate w1/w2, a base of vectors for the grid
            w1 = Q - P;
            w1 = w1 ./ sqrt(sum(w1.^2,2));
            w2 = cross(w1, GridNormal);
            w2 = w2 ./ sqrt(sum(w2.^2,2));
            % Position of the third corner (S)
            S = P + S1 * w1 + S2 * w2;
            % Base U and V of vectors to define the grid
            U = S-P;
            N = cross(U, Q-P);
            V = - cross(U, N);
            % Normalize base vectors to the unit of the grid
            unitY = sqrt(sum((Q-S).^2,2)) ./ (nCols - 1);
            U = U ./ sqrt(sum(U.^2,2)) .* unitX;   % Rows
            V = V ./ sqrt(sum(V.^2,2)) .* unitY;   % Cols
            % Position of the realigned electrodes
            NewLoc = bst_bsxfun(@plus, P, (I-1) * U + (J-1)*V);
            
        % Grids: four corners
        case 4
            % Get 4 possible coordinates for the point, from the four corners
            Xp = bst_bsxfun(@plus, P,     (I-1)/(nRows-1)*(S-P) +     (J-1)/(nCols-1)*(T-P));
            Xt = bst_bsxfun(@plus, T,     (I-1)/(nRows-1)*(Q-T) + (nCols-J)/(nCols-1)*(P-T));
            Xs = bst_bsxfun(@plus, S, (nRows-I)/(nRows-1)*(P-S) +     (J-1)/(nCols-1)*(Q-S));
            Xq = bst_bsxfun(@plus, Q, (nRows-I)/(nRows-1)*(T-Q) + (nCols-J)/(nCols-1)*(S-Q));
            % Weight the four options based on their norm to the point, in grid spacing
            m = (nRows-1)^2 + (nCols-1)^2;
            wp = m - (    (I-1).^2 +     (J-1).^2);
            wt = m - (    (I-1).^2 + (nCols-J).^2);
            ws = m - ((nRows-I).^2 +     (J-1).^2);
            wq = m - ((nRows-I).^2 + (nCols-J).^2);
            NewLoc = (bst_bsxfun(@times, wp, Xp) + ...
                      bst_bsxfun(@times, wt, Xt) + ...
                      bst_bsxfun(@times, ws, Xs) + ...
                      bst_bsxfun(@times, wq, Xq));
            NewLoc = bst_bsxfun(@rdivide, NewLoc, wp + wt + ws + wq);                    
    end
    % Project on the inner skull
    [NewOrient, NewLoc] = figure_3d('GetChannelNormal', sSubject, NewLoc);
    % Replace original channel positions
    for i = 1:nElec
        Channels(iChan(i)).Loc(:,1) = NewLoc(i,:)';
    end
end


%% ===== SET ELECTRODE TIP =====
function SetElectrodeLoc(iLoc)
    global GlobalData;
    % Get selected electrodes
    [sSelElec, iSelElec, iDS, iFig, hFig] = GetSelectedElectrodes();
    if isempty(sSelElec)
    	bst_error('No electrode seleced.', 'Set electrode position', 0);
        return;
    elseif (length(sSelElec) > 1)
        bst_error('Multiple electrodes selected.', 'Set electrode position', 0);
        return;
    elseif ~strcmpi(GlobalData.DataSet(iDS).Figure(iFig).Id.Type, 'MriViewer')
        bst_error('Position must be set from the MRI viewer.', 'Set electrode position', 0);
        return;
    elseif (size(sSelElec.Loc, 2) < iLoc-1)
        bst_error('Set the first contact of the electrode first.', 'Set electrode position', 0);
        return;
    end
    % Get selected coordinates
    sMri = panel_surface('GetSurfaceMri', hFig);
    XYZ = figure_mri('GetLocation', 'scs', sMri, GlobalData.DataSet(iDS).Figure(iFig).Handles);
    % Make sure the two points of the electrode are more than 1cm apart
    if ((size(sSelElec.Loc,2) >= 1) && (iLoc == 2) && (sqrt(sum((sSelElec.Loc(:,1) - XYZ(:)).^2)) < 0.01)) || ...
       ((size(sSelElec.Loc,2) >= 2) && (iLoc == 1) && (sqrt(sum((sSelElec.Loc(:,2) - XYZ(:)).^2)) < 0.01))
        bst_error('The two points you selected are less than 1cm away.', 'Set electrode position', 0);
        return;
    end
    % Set electrode position
    sSelElec.Loc(:,iLoc) = XYZ(:);
    % Save electrode modification
    SetElectrodes(iSelElec, sSelElec);
    % If the electrode is incomplete, nothing else to do
    if (size(sSelElec.Loc,2) == 1)
        return;
    end
    % Get the contact for this electrode
    iChan = find(strcmpi({GlobalData.DataSet(iDS).Channel.Group}, sSelElec.Name));
    % Update contact positions
    if ~isempty(iChan)
        % If the positions are not set, set positions automatically
        if any(cellfun(@(c)or(isempty(c), isequal(c,[0;0;0])), {GlobalData.DataSet(iDS).Channel(iChan).Loc}))
            isAlign = 1;
        % Otherwise, ask for confirmation to the user
        else
            isAlign = java_dialog('confirm', 'Update the positions of the contacts?', 'Set electrode position');
        end
        % Set contact position
        if isAlign
            AlignContacts(iDS, iFig, 'default');
        end
    end
    % Update display
    UpdateFigures();        
 
end


