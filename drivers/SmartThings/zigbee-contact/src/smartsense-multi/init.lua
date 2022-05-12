local capabilities     = require "st.capabilities"
local multi_utils = require "multi-sensor/multi_utils"

local ACCELERATION_MASK = 0x01
local CONTACT_MASK = 0x02
local SMARTSENSE_MULTI_CLUSTER = 0xFC03
local SMARTSENSE_MULTI_ACC_CMD = 0x00
local SMARTSENSE_MULTI_XYZ_CMD = 0x05
local SMARTSENSE_MULTI_STATUS_CMD = 0x07
local SMARTSENSE_MULTI_STATUS_REPORT_CMD = 0x09

local function acceleration_handler(driver, device, zb_rx)
  -- This is a custom cluster command for the kickstarter multi.
  -- This has no body but is sent everytime the accelerometer transitions from an unmoving state to a moving one.
  device:emit_event(capabilities.accelerationSensor.acceleration.active())
end

local function battery_handler(device, value, zb_rx)
  local MAX_VOLTAGE = 3.0
  local batteryPercentage = math.min(math.floor(((value / MAX_VOLTAGE) * 100) + 0.5), 100)

  if batteryPercentage ~= nil then
    device:emit_event_for_endpoint(
      zb_rx.address_header.src_endpoint.value,
      capabilities.battery.battery(batteryPercentage)
    )
  end
end

local function contact_handler(device, value)
  local event
  if value == 0x01 then
    event = capabilities.contactSensor.contact.open()
  else
    event = capabilities.contactSensor.contact.closed()
  end
  if event ~= nil then
    device:emit_event(event)
  end
end

local function temperature_handler(device, temperature)
  -- legacy code (C):
  -- Value is in tenths of a degree so divide by 10.
  -- tempEventVal = ((float)attrVal.int16Val) / 10.0 + tempOffsetVal
  -- tempOffset is handled outside of the driver
  local tempDivisor = 10.0
  local tempCelsius = temperature / tempDivisor
  device:emit_event(capabilities.temperatureMeasurement.temperature({value = tempCelsius, unit = "C"}))
end

local function status_handler(driver, device, zb_rx)
  -- This is a custom cluster command for the kickstarter multi.  It contains 2 fields
  -- a temp field and a status field
  -- The status fields is further broken up into 3 bit values:
  --   bit 0 is 1 if acceleration is active otherwise 0.
  --   bit 1 is 1 if the contact sensor is open otherwise 0
  --   bit 2-7 is a 6 bit battery voltage value in tenths of a volt
  local batteryDivisor = 10
  local temperature = zb_rx.body.zcl_body.body_bytes:byte(1)
  local status = zb_rx.body.zcl_body.body_bytes:byte(2)
  local acceleration = status & ACCELERATION_MASK
  local contact = (status & CONTACT_MASK) >> 1
  local battery = (status >> 2) / batteryDivisor
  multi_utils.handle_acceleration_report(device, acceleration)
  contact_handler(device, contact)
  battery_handler(device, battery, zb_rx)
  temperature_handler(device, temperature)
end

local function status_report_handler(driver, device, zb_rx)
  -- This is a custom cluster command for the kickstarter multi.  It contains 3 fields
  -- a temp field, a status field and a battery voltage field (this field is battery voltage * 40).
  -- The status fields is further broken up into 2 bit values:
  --   bit 0 is 1 if acceleration is active otherwise 0.
  --   bit 1 is 1 if the contact sensor is open otherwise 0
  local batteryDivisor = 40
  local temperature = zb_rx.body.zcl_body.body_bytes:byte(1)
  local status = zb_rx.body.zcl_body.body_bytes:byte(2)
  local acceleration = status & ACCELERATION_MASK
  local contact = (status & CONTACT_MASK) >> 1
  local battery = zb_rx.body.zcl_body.body_bytes:byte(3) / batteryDivisor
  multi_utils.handle_acceleration_report(device, acceleration)
  contact_handler(device, contact)
  battery_handler(device, battery, zb_rx)
  temperature_handler(device, temperature)
end


local function xyz_handler(driver, device, zb_rx)
  -- This is a custom cluster command for the kickstarter multi.
  -- It contains 3 2 byte signed integers which are X,Y,Z acceleration values that are used to define orientation.
  local x = multi_utils.convert_to_signedInt16(zb_rx.body.zcl_body.body_bytes:byte(1), zb_rx.body.zcl_body.body_bytes:byte(2))
  local y = multi_utils.convert_to_signedInt16(zb_rx.body.zcl_body.body_bytes:byte(3), zb_rx.body.zcl_body.body_bytes:byte(4))
  local z = multi_utils.convert_to_signedInt16(zb_rx.body.zcl_body.body_bytes:byte(5), zb_rx.body.zcl_body.body_bytes:byte(6))
  multi_utils.handle_three_axis_report(device, x, y, z)
end

local smartsense_multi = {
  NAME = "SmartSense Multi",
  zigbee_handlers = {
    cluster = {
      [SMARTSENSE_MULTI_CLUSTER] = {
        [SMARTSENSE_MULTI_ACC_CMD] = acceleration_handler,
        [SMARTSENSE_MULTI_XYZ_CMD] = xyz_handler,
        [SMARTSENSE_MULTI_STATUS_CMD] = status_handler,
        [SMARTSENSE_MULTI_STATUS_REPORT_CMD] = status_report_handler
      }
    }
  },
  can_handle = function(opts, driver, device, ...)
    local sp = device:supports_server_cluster(SMARTSENSE_MULTI_CLUSTER, 1)
    return sp
  end
}

return smartsense_multi