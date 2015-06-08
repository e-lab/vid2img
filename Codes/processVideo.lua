--------------------------------------------------------------------
-- processVideo module                      ------------------------
-- From Alfredo's original version          ------------------------
-- Jarvis Du -------------------------------------------------------
-- Dec 3, 2014 -----------------------------------------------------
-- Videos, images, labels locations are illustrated in -------------
-- vid2img.lua -----------------------------------------------------
--------------------------------------------------------------------

-- Requires --------------------------------------------------------
require 'sys'
require 'qtuiloader'
require 'qtwidget'
require 'pl'
require 'image'
video_decoder = require('libvideo_decoder')
-- Sub-Fuction definition ------------------------------------------
function VideoRead(videoPath)
   -- By Alf's test-frame.lua --------------------------------------
   io.write(videoPath .. '\n')
   status, height, width, length, fps =  video_decoder.init(videoPath)
end

function findMatch(xOld, yOld)
   local Delta = 20
   local execu = 1
   -- img size
   out_pic = 0
   if xOld - Delta < 1 or yOld - Delta < 1 or xOld + x2 - x1 + Delta > width or yOld + y2 - y1 + Delta > height then
      execu = 0
      ui.frame_2.can_label.text = 'The searching area is greater than the input image! Re-draw the rectangle >:['
      out_pic = 1
      return 0, 0
   end
   if execu == 1 then
      SAD = torch.FloatTensor(2*Delta+1, 2*Delta+1)
      for i = yOld-Delta, yOld+Delta do
         for j = xOld-Delta, xOld+Delta do
            -- sum function
            SAD[i-yOld+Delta+1][j-xOld+Delta+1] = ((dst[{{}, {i, i+y2-y1}, {j, j+x2-x1}}]):long() - patch:long()):abs():sum()
         end
      end
      win2 = image.display{image = image.y2jet(SAD:clone():mul(255/SAD:max()):add(1)), win = win2, zoom = 4}
      min_y = yOld - Delta
      min_x = xOld - Delta
      min_value = SAD:min()
      for i = yOld-Delta, yOld+Delta do
         for j = xOld-Delta, xOld+Delta do
            if SAD[i-yOld+Delta+1][j-xOld+Delta+1] == min_value then
               min_y = i
               min_x = j
            end
         end
      end
      return min_x, min_y
   end
end

pause_n = 0
function ui_pause()
   if (interr == 1) then
      return
   end
   pause_n = 1 - pause_n
   if (pause_n == 1) then
      ui.frame.button_pause.text = 'Play ▶'
   else
      ui.frame.button_pause.text = 'Pause ▶▮'
   end
   qt.doevents()
end

function ui_skip()
   skip = 1 - skip
   if (skip) then
      ui.frame.button_skip:setDisabled(1)
   end
   qt.doevents()
end

function ui_reset()
   reset = 1
end

function ui_done()
   done = 1
end

interr = 0
function sleep(n)
   os.execute("sleep " .. tonumber(n))
end

function ui_select(x, y)
   if (interr == 0) then
      return
   end
   if (x1 == -1) then
      x1 = x
      y1 = y
   else
      x2 = x
      y2 = y
      min_x = math.min(x1, x2)
      min_y = math.min(y1, y2)
      max_x = math.max(x1, x2)
      max_y = math.max(y1, y2)
      x1 = min_x
      x2 = max_x
      y1 = min_y
      y2 = max_y
      interr = 0
   end
end

out_pic = 0
function processVideo(v_class, vid)
   -- video_decoder has all the information of every frame
   VideoRead('../Videos/' .. v_class .. '/' .. vid)
   -- open .dat file for recording
   labelFileID = io.open('../labels/' .. v_class .. '/' .. vid .. '.dat', 'w')
   labelFileID:write('name,x,y,w,h\n');
   -- initialize the button variable
   reset = 0
   skip = 0
   ui.frame.button_reset:setEnabled(1)
   done = 0 -- done as variable
   start_trigger = 0;
   -- video parameters --
   local nb_frames = length
   -- Process for every frame
   blank_dst = torch.ByteTensor(3, height, width)
   -- Scales
   for f = 0, nb_frames do -- Define video
      dst = torch.ByteTensor(3, height, width)
      video_decoder.frame_rgb(dst)
      xRatio = dst:size()[2]/360.0
      yRatio = dst:size()[3]/640.0
      -- Set horizontal slider and label
      ui.frame_2.progslide:setValue((f + 1)/nb_frames*100)
      ui.frame_2.framenum:setText('Current frame: ' .. (f+1) .. '/' .. nb_frames)
      -- Set "win:gbegin()" for rectangle
      if (f > 0) then
         win:gbegin()
      end
      dst_bk = dst:clone()
      dst = image.scale(dst, 640, 360)
      img_win = image.display{image = dst, win = win}
      qt.doevents()
      if (f == 0) then
         x1 = -1
         y1 = -1
         x2 = 0
         y2 = 0
         ui.frame_2.can_label.text = 'Draw a rectangle around the object you want to track...'
         interr = 1
         while (1) do
            sleep(0.25)
            qt.doevents()
            if (done == 1) then
               video_decoder.exit()
               labelFileID.close()
               return
            end
            if (skip == 1) then
               break
            end
            if (interr == 0) then
               qt.doevents()
               img_win.rectangle(win, x1, y1, x2 - x1, y2 - y1)
               img_win.stroke(win)
               patch = dst[{{}, {y1, y2}, {x1, x2}}]
               x = x1
               xOld = x1
               y = y1
               yOld = y1
               break
            end
         end
         interr = 0
      else
         if (reset == 1) then
            reset = 0
            x1 = -1
            y1 = -1
            x2 = 0
            y2 = 0
            interr = 1
            while (1) do
               sleep(0.25)
               qt.doevents()
               if (done == 1) then
                  video_decoder.exit()
                  labelFileID.close()
                  return
               end
               if (interr == 0) then
                  qt.doevents()
                  img_win.rectangle(win, x1, y1, x2 - x1, y2 - y1)
                  img_win.stroke(win)
                  patch = dst[{{}, {y1, y2}, {x1, x2}}]
                  x = x1
                  xOld = x1
                  y = y1
                  yOld = y1
                  break
               end
            end
            pause_n = 0
            ui.frame.button_pause.text = 'Pause ▶▮'
            skip = 0
            ui.frame.button_skip:setEnabled(1)
         else
            if (pause_n == 1) then
               ui.frame_2.can_label.text = 'Paused...'
               while (1) do
                  sleep(0.25)
                  qt.doevents()
                  if (done == 1) then
                     break
                  end
                  if (pause_n == 0) then
                     break
                  end
                  if (reset == 1) then
                     ui.frame_2.can_label.text = 'Please specify the new rectangle.'
                     break
                  end
               end
            else
               if (skip == 1) then
                  ui.frame_2.can_label.text = 'Skipping...'
                  if (tostring(ui.frame.skip_f.text) == '0') then
                     while (1) do
                        if (done == 1) then
                           break
                        end
                        sleep(tostring(2))
                        qt.doevents()
                        if (tostring(ui.frame.skip_f.text) ~= '0') then
                           break
                        end
                        if (pause_n == 1) then
                           break
                        end
                        if (reset == 1) then
                           ui.frame_2.can_label.text = 'Please specify the new rectangle.'
                           break
                        end
                     end
                  else if (tostring(ui.frame.skip_f.text) ~= '') then
                          sleep(tostring(1/tonumber(tostring(ui.frame.skip_f.text))))
                       end
                       qt.doevents()
                       if (reset == 1) then
                          ui.frame_2.can_label.text = 'Please specify the new rectangle.'
                       end
                  end
               else
                  ui.frame_2.can_label.text = 'Tracked Object'
                  qt.doevents()
                  x, y = findMatch(xOld, yOld)
                  if (out_pic == 1) then
                     img_win.rectangle(win, x1, y1, x2 - x1, y2 - y1)
                     img_win:setcolor('red')
                     img_win:setlinewidth(5)
                     img_win.stroke(win)
                     win:gend()
                     reset = 1
                     ui.frame_2.can_label.text = 'Searching area out of picture. Please re-draw the rectangle.'
                  else
                     h = x2 - x1
                     w = y2 - y1
                     x1 = x
                     x2 = x + h
                     y1 = y
                     y2 = y + w
                     if math.max(math.abs(xOld-x), math.abs(y-yOld)) >= 16 then
                        reset = 1
                        ui.frame_2.can_label.text = 'Seraching area moving too fast out of searching area. Please re-draw the rectangle.'
                     else
                        img_win.rectangle(win, x1, y1, x2 - x1, y2 - y1)
                        img_win:setcolor('red')
                        img_win:setlinewidth(5)
                        img_win.stroke(win)
                        xOld = x
                        yOld = y
                        labelFileID:write(string.format('%s-%04d.png,%d,%d,%d,%d\n', vid, f, torch.round(x*xRatio), torch.round(y*yRatio), torch.round((x2 - x1)*xRatio), torch.round((y2 - y1)*yRatio)));
                        image.save(string.format('../images/' .. v_class .. '/%s-%04d.png', vid, f), dst_bk:float()/dst_bk:max())
                        qt.doevents()
                        if (reset == 1) then
                           ui.frame_2.can_label.text = 'Please specify the new rectangle.'
                        end
                     end
                  end
               end
            end
         end
      end
      if (done == 1) then
         video_decoder.exit()
         labelFileID.close()
         return
      end
      if (f > 0) then
         win:gend()
      end
   end

   video_decoder.exit()
   -- close file
   labelFileID.close()
   io.write(' + + + Processing completed succesfully')
end
