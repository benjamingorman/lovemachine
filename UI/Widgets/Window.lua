require "UI.Hierarchy"
require "UI.Widgets.Button"
require "UI.Widgets.Widget"

Window = {}
Window.__index = Window
setmetatable(Window, Widget)

function Window.new(x,y, width,height, settings) local self = Widget.new(x, y, width, height)
    self.title = "Untitled"
    self.borderSize = Settings.windowBorderSize
    self.borderColor = Settings.windowBorderColor
    self.mouseoverBorderColor = Settings.windowMouseoverBorderColor
    self.backgroundColor = Settings.windowBackgroundColor
    self.statusBarTextPadding = Settings.windowStatusBarTextPadding
    self.statusBarHeight = Window.getStatusBarHeight()

    self.hierarchy = Hierarchy.new(self)
    self.isMouseover = false 
    self.beingDragged = false
    self.closable = true

    if settings then
        if settings.title then self.title = settings.title end
        if settings.closable then self.closable = settings.closable end
    end

    setmetatable(self, Window)
    if self.closable then -- make a close button
        self:addButton(Button.new(0,0, function() self:close() end))
    end

    return self 
end

-- Automatically create a window with the correct size to fit the widget.
function Window.newWithWidget(x,y,widget,settings)
    local w = widget.width + Settings.windowBorderSize * 2
    local h = widget.height + Window.getStatusBarHeight() + Settings.windowBorderSize

    local self = Window.new(x,y,w,h,settings)  
    self:addWidget(widget)
    return self
end

function Window:update(dt)
    if self.beingDragged then
        mx, my = love.mouse.getPosition()
        dx, dy = mx - self.oldMousePosition.x, my - self.oldMousePosition.y
        self.x = self.x + dx
        self.y = self.y + dy
        self.hierarchy:translate(dx,dy)
        self.oldMousePosition = {x=mx, y=my}
    end
    self.hierarchy:update(dt)
    self.isMouseover = false
end

function Window:draw()
    -- Draw border
    if self.isMouseover then
        love.graphics.setColor( unpack(self.mouseoverBorderColor) )
    else
        love.graphics.setColor( unpack(self.borderColor) )
    end
    love.graphics.rectangle("fill", self.x, self.y,
                                    self.width, self.height)

    -- Draw status bar
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.statusBarHeight) 
    love.graphics.setColor(255,255,255)
    love.graphics.printf(self.title, self.x + self.statusBarTextPadding,
                         self.y + self.statusBarTextPadding, self.width - self.statusBarTextPadding)

    -- Draw background
    love.graphics.setColor( unpack(self.backgroundColor) )
    love.graphics.rectangle("fill", self.x + self.borderSize, self.y + self.statusBarHeight,
                                    self.width - 2 * self.borderSize,
                                    self.height - self.statusBarHeight - self.borderSize)

    -- Draw window contents.
    love.graphics.setColor(255,255,255)
    self.hierarchy:draw()
end

function Window.getStatusBarHeight()
    return love.graphics.getFont():getHeight() + 2 * Settings.windowStatusBarTextPadding   
end

function Window:addWidget(widget)
    widget.x = widget.x + self.x + self.borderSize
    widget.y = widget.y + self.y + self.statusBarHeight
    self.hierarchy:addWidget(widget)
end

function Window:addButton(buttonWidget)
    -- TODO: make this use a packing algorithm so it's easy to add multiple buttons.
    buttonWidget.x = self.x + self.width - self.borderSize - buttonWidget.width
    buttonWidget.y = self.y + Settings.windowStatusBarTextPadding
    self.hierarchy:addWidget(buttonWidget)
end

function Window:close()
    self._deleted = true
end

function Window:mouseover(mx,my)
    self.isMouseover = true
    self.hierarchy:mouseover(mx,my)
end

function Window:mousepressed(mx, my, button)
    -- Check to see if the status bar was pressed, if so then drag it else just pass the event to children.
    self._parentHierarchy:elevateWidget(self._id)
    if my <= self.y + self.statusBarHeight then
        local anyButtonsPressed = self.hierarchy:mousepressed(mx,my,button)

        if not anyButtonsPressed then
            self.oldMousePosition = {x = love.mouse.getX(), y = love.mouse.getY()}
            self.beingDragged = true
        end
    else
        self.hierarchy:mousepressed(mx, my, button)
    end
end

function Window:mousereleased(mx, my, button)
    self.beingDragged = false
    self.hierarchy:mousereleased(mx, my, button)
end

function Window:keypressed(key)
    self.hierarchy:keypressed(key)
end

function Window:keyreleased(key)
    self.hierarchy:keyreleased(key)
end