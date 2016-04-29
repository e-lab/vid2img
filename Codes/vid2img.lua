-----------------------------------------------------------------------------------
-- This version is converted from Alf's vid2img MATLAB code to torch version.
-- Interface by Qt
-- torch_version/src/codes/vim2img.lua
-- Videos, images, labels located in
-- torch_version/src/videos
-- torch_version/src/images
-- torch_version/src/labels
-----------------------------------------------------------------------------------
-- Jarvis Du
-- Feb 10, 2015
-----------------------------------------------------------------------------------
-- Revised Version ---
-- Revised Version ---
-- Revised Version ---


-- Requires -----------------------------------------------------------------------
require 'sys'
require 'processVideo'
require 'qtuiloader'
require 'qtwidget'
require 'pl'
require 'image'
video_decoder = require('libvideo_decoder')

-- Function definitions -----------------------------------------------------------
function getFilesName(pathName)
   list = {}
   i = 0
   for name in io.popen('ls ' .. pathName):lines() do
      if name ~= 'exampleFolder' then
         i = i + 1
         list[i] = name
      end
   end
   return list
end

function makeCorrDir(className)
   chList = {'images', 'labels'}
   for i = 1, 2 do
      chMainFolder = io.open('../' .. chList[i])
      if chMainFolder == nil then
         print('mkdir ../' .. chList[i])
         os.execute('mkdir ../' .. chList[i])
      end
      chClass = io.open('../' .. chList[i] .. '/'.. className)
      if chClass == nil then
         os.execute('mkdir ' .. '../' .. chList[i] .. '/' .. className)
      end
   end
end
-- UI functions ------------------------------------------------------------------'
videos = {}
function ui_q_yes()
   ui_q:close()
   if videoClasses[class] ~= 'exampleFolder' and videoClasses[class] ~= 'bckg' and videoClasses[class] ~= '' and videoClasses[class] ~= '.DS_Store' then
      if (current == 0) then
         makeCorrDir(videoClasses[class])
         videos = getFilesName('../Videos/' .. videoClasses[class])
         v = 1
         if (v <= #videos) then
            ui_q.hint.setText(ui_q.hint, 'Would you like to process ' .. videoClasses[class] .. '/' .. videos[v] .. '?')
            current = 1
            ui_q:show()
            return
         end
      else
         win:close()
         win = qt.QtLuaPainter(ui.frame_2.canvas)
         --test_process()
         processVideo(videoClasses[class], videos[v])
         v = v + 1
         if (v <= #videos) then
            ui_q.hint.setText(ui_q.hint, 'Would you like to process ' .. videoClasses[class] .. '/' .. videos[v] .. '?')
            ui_q:show()
            return
         end
      end
   end

   class = class + 1
   if (class <= #videoClasses) then
      ui_q.hint.setText(ui_q.hint, 'Would you like to process ' .. videoClasses[class] .. '?')
      current = 0
      ui_q:show()
   else
      os.exit()
   end
end

function ui_q_no()
   ui_q:close()
   if (current == 0) then
      class = class + 1
      if (class <= #videoClasses) then
         ui_q.hint.setText(ui_q.hint, 'Would you like to process ' .. videoClasses[class] .. '?')
         ui_q:show()
      end
   else
      v = v + 1
      if (v <= #videos) then
         ui_q.hint.setText(ui_q.hint, 'Would you like to process ' .. videoClasses[class] .. '/' .. videos[v] .. '?')
         ui_q:show()
      else
         current = 0
         class = class + 1
         if (class <= #videoClasses) then
            ui_q.hint.setText(ui_q.hint, 'Would you like to process ' .. videoClasses[class] .. '?')
            ui_q:show()
         else
            os.exit()
         end
      end
   end
end


function ui_load_info(ent)
   if (ent == 1) then
      ui.stat:showMessage("To continue the tracking process if it is paused.")
   else
      ui.stat:showMessage("")
   end
end

function ui_pause_info()
   ui.stat:showMessage("To pause the tracking process in the middle.")
end

function ui_skip_info()
   ui.stat:showMessage("To skip the frames at a specified speed.")
end

function ui_reset_info()
   ui.stat:showMessage("To reset the rectangle.")
end

function ui_done_info()
   ui.stat:showMessage("To halt current picture.")
end

-- Initialization window ----------------------------------------------------------
ui = qtuiloader.load('../GUI/vid2img.ui')
win = qt.QtLuaPainter(ui.frame_2.canvas)
win2 = qt.QtLuaPainter(ui.canvas_2)
win_logo = qt.QtLuaPainter(ui.logo)
logo = image.scale(image.load('../GUI/logo.jpg'), 70, 70)
img_logo = image.display{image = logo, win = win_logo}
qt.connect(qt.QtLuaListener(ui.frame.button_pause), 'sigMousePress(int,int,QByteArray,QByteArray,QByteArray)', ui_pause)
qt.connect(qt.QtLuaListener(ui.frame.button_skip), 'sigMousePress(int,int,QByteArray,QByteArray,QByteArray)', ui_skip)
qt.connect(qt.QtLuaListener(ui.frame.button_reset), 'sigMousePress(int,int,QByteArray,QByteArray,QByteArray)', ui_reset)
qt.connect(qt.QtLuaListener(ui.frame.button_done), 'sigMousePress(int,int,QByteArray,QByteArray,QByteArray)', ui_done)
qt.connect(qt.QtLuaListener(ui.frame_2.canvas), 'sigMousePress(int,int,QByteArray,QByteArray,QByteArray)', ui_select)
ui:show()

-- Local definitions --------------------------------------------------------------

-- Main program -------------------------------------------------------------------
-- Initialize question box --------------------------------------------------------
videoClasses = getFilesName('../Videos/')
class = 1
current = 0
ui_q = qtuiloader.load('../GUI/question.ui')
qt.connect(qt.QtLuaListener(ui_q.yes), 'sigMousePress(int,int,QByteArray,QByteArray,QByteArray)', ui_q_yes)
qt.connect(qt.QtLuaListener(ui_q.no), 'sigMousePress(int,int,QByteArray,QByteArray,QByteArray)', ui_q_no)
ui_q.hint.setText(ui_q.hint, 'Would you like to process ' .. videoClasses[class] .. '?')
ui_q:show()
--[[
for class = 1, #videoClasses do
   if videoClasses[class] ~= 'exampleFolder' and videoClasses[class] ~= 'bckg' and videoClasses[class] ~= '' and videoClasses[class] ~= '.DS_Store' then
      -- io.write('Would you like to process ' .. videoClasses[class] .. '? (y/[n]) ')
      if message_question(videoClass[class]) then
         io.write(' + Processing class ' .. videoClasses[class] .. '\n')
         makeCorrDir(videoClasses[class]) -- mkdir in figures and labels folders
         videos = getFilesName('../Videos/' .. videoClasses[class])
         for v = 1, #videos do
            if videos[v] ~= '' and videos[v] ~= '.DS_Store' then
               io.write(' + + Would you like to process ' .. videoClasses[class] .. '/' .. videos[v] .. '? (y/[n]) ')
               if io.read() == 'y' then
                  processVideo(videoClasses[class], videos[v])
               else
                  io.write(' + + + Skipping video ' .. videoClasses[class] .. '/' .. videos[v] .. '\n')
               end
            end
         end
         io.write(' + Completed processing of class ' .. videoClasses[class] .. '\n')
      else
         io.write(' + Skipping class ' .. videoClasses[class] .. '\n')
      end
   end
end

io.write('No more classes to process. Existing. \n\n')
--]]
