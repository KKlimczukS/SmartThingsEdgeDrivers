-- Copyright 2022 SmartThings
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Mock out globals
local test = require "integration_test"
local clusters = require "st.zigbee.zcl.clusters"
local OnOff = clusters.OnOff
local Level = clusters.Level
local PowerConfiguration = clusters.PowerConfiguration
local capabilities = require "st.capabilities"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local FrameCtrl = require "st.zigbee.zcl.frame_ctrl"
local t_utils = require "integration_test.utils"

local zigbee_battery_accessory_dimmer_profile = t_utils.get_profile_definition("switch-battery-level.yml")

local mock_device_sengled = test.mock_device.build_test_zigbee_device(
    {
      profile = zigbee_battery_accessory_dimmer_profile,
      fingerprinted_endpoint_id = 0x01,
      zigbee_endpoints = {
        [1] = {
          id = 1,
          manufacturer = "sengled",
          model = "E1E-G7F",
          server_clusters = {0x0000, 0x0001, 0x0003, 0x0020, 0xFC11},
          client_clusters = {0x0003, 0x0004, 0x0006, 0x0008, 0xFC10},
        }
      }
    }
)

local mock_device_ikea = test.mock_device.build_test_zigbee_device(
    {
      profile = zigbee_battery_accessory_dimmer_profile,
      fingerprinted_endpoint_id = 0x01,
      zigbee_endpoints = {
        [1] = {
          id = 1,
          manufacturer = "IKEA of Sweden",
          model = "TRADFRI wireless dimmer",
          server_clusters = {0x0000, 0x0001, 0x0003, 0x0009, 0x0B05, 0x1000}
        }
      }
    }
)

local mock_device_centralite = test.mock_device.build_test_zigbee_device(
    {
      profile = zigbee_battery_accessory_dimmer_profile,
      fingerprinted_endpoint_id = 0x01,
      zigbee_endpoints = {
        [1] = {
          id = 1,
          manufacturer = "Centralite Systems",
          model = "3131-G",
          server_clusters = {0x0000, 0x0001, 0x0003, 0x0020, 0x0B05}
        }
      }
    }
)

zigbee_test_utils.prepare_zigbee_env_info()

local function test_init()
  test.mock_device.add_test_device(mock_device_sengled)
  test.mock_device.add_test_device(mock_device_ikea)
  test.mock_device.add_test_device(mock_device_centralite)
  zigbee_test_utils.init_noop_health_check_timer()
end

test.set_test_init_function(test_init)

test.register_message_test(
  "Battery percentage report should be handled",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = { mock_device_ikea.id, PowerConfiguration.attributes.BatteryPercentageRemaining:build_test_attr_report(mock_device_ikea, 55) }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device_ikea:generate_test_message("main", capabilities.battery.battery(55))
    }
  }
)

test.register_message_test(
  "OnOff clster On command should be handled",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = {
        mock_device_sengled.id,
        OnOff.server.commands.On.build_test_rx(mock_device_sengled)
      }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device_sengled:generate_test_message("main", capabilities.switch.switch.on())
    }
  }
)

test.register_message_test(
  "OnOff clster Off command should be handled",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = {
        mock_device_sengled.id,
        OnOff.server.commands.Off.build_test_rx(mock_device_sengled)
      }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device_sengled:generate_test_message("main", capabilities.switch.switch.off())
    }
  }
)

test.register_message_test(
  "OnOff clster Off command should be handled",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = {
        mock_device_sengled.id,
        OnOff.server.commands.Off.build_test_rx(mock_device_sengled)
      }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device_sengled:generate_test_message("main", capabilities.switch.switch.off())
    }
  }
)

local SENGLED_MFR_SPECIFIC_CLUSTER = 0xFC10
local SENGLED_MFR_SPECIFIC_COMMAND = 0x00
local SENGLED_MFR_CODE = 0x1160

test.register_message_test(
  "manufacturer(sengled) specific clster command(\x01\x00\x00\x00) should be handled",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = {
        mock_device_sengled.id,
        zigbee_test_utils.build_custom_command_id(mock_device_sengled, SENGLED_MFR_SPECIFIC_CLUSTER, SENGLED_MFR_SPECIFIC_COMMAND, SENGLED_MFR_CODE, "   ")
      }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device_sengled:generate_test_message("main", capabilities.switch.switch.on())
    }
  }
)

test.register_message_test(
  "manufacturer(sengled) specific clster command(\x02\x00\x01\x00) should be handled",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = {
        mock_device_sengled.id,
        zigbee_test_utils.build_custom_command_id(mock_device_sengled, SENGLED_MFR_SPECIFIC_CLUSTER, SENGLED_MFR_SPECIFIC_COMMAND, SENGLED_MFR_CODE, "  ")
      }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device_sengled:generate_test_message("main", capabilities.switch.switch.on())
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device_sengled:generate_test_message("main", capabilities.switchLevel.level(5))
    }
  }
)

test.register_message_test(
  "manufacturer(sengled) specific clster command(\x02\x00\x02\x00) should be handled",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = {
        mock_device_sengled.id,
        zigbee_test_utils.build_custom_command_id(mock_device_sengled, SENGLED_MFR_SPECIFIC_CLUSTER, SENGLED_MFR_SPECIFIC_COMMAND, SENGLED_MFR_CODE, "  ")
      }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device_sengled:generate_test_message("main", capabilities.switch.switch.on())
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device_sengled:generate_test_message("main", capabilities.switchLevel.level(10))
    }
  }
)

test.register_message_test(
  "manufacturer(sengled) specific clster command(\x02\x00\x02\x00) should be handled",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = {
        mock_device_sengled.id,
        zigbee_test_utils.build_custom_command_id(mock_device_sengled, SENGLED_MFR_SPECIFIC_CLUSTER, SENGLED_MFR_SPECIFIC_COMMAND, SENGLED_MFR_CODE, "  ")
      }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device_sengled:generate_test_message("main", capabilities.switch.switch.on())
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device_sengled:generate_test_message("main", capabilities.switchLevel.level(10))
    }
  }
)

test.register_coroutine_test(
  "manufacturer(sengled) specific clster command(\x03\x00\x01\x00) should be handled",
  function()
    test.timer.__create_and_queue_test_time_advance_timer(1, "oneshot")

    test.socket.capability:__queue_receive({mock_device_sengled.id, { capability = "switchLevel", component = "main", command = "setLevel", args = { 57 } }})
    test.socket.capability:__expect_send(mock_device_sengled:generate_test_message("main", capabilities.switch.switch.on({ state_change = true })))
    test.wait_for_events()
    test.mock_time.advance_time(1)
    test.socket.capability:__expect_send(mock_device_sengled:generate_test_message("main", capabilities.switchLevel.level(57)))
    test.wait_for_events()

    test.socket.zigbee:__queue_receive({ mock_device_sengled.id, zigbee_test_utils.build_custom_command_id(mock_device_sengled, SENGLED_MFR_SPECIFIC_CLUSTER, SENGLED_MFR_SPECIFIC_COMMAND, SENGLED_MFR_CODE, "  ") })
    test.socket.capability:__expect_send(mock_device_sengled:generate_test_message("main", capabilities.switch.switch.on()))
    test.socket.capability:__expect_send(mock_device_sengled:generate_test_message("main", capabilities.switchLevel.level(52)))
  end
)

test.register_message_test(
  "manufacturer(sengled) specific clster command(\x03\x00\x02\x00) should be handled",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = {
        mock_device_sengled.id,
        zigbee_test_utils.build_custom_command_id(mock_device_sengled, SENGLED_MFR_SPECIFIC_CLUSTER, SENGLED_MFR_SPECIFIC_COMMAND, SENGLED_MFR_CODE, "  ")
      }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device_sengled:generate_test_message("main", capabilities.switch.switch.off())
    },
  }
)

test.register_message_test(
  "manufacturer(sengled) specific clster command(\x04\x00\x00\x00) should be handled",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = {
        mock_device_sengled.id,
        zigbee_test_utils.build_custom_command_id(mock_device_sengled, SENGLED_MFR_SPECIFIC_CLUSTER, SENGLED_MFR_SPECIFIC_COMMAND, SENGLED_MFR_CODE, "   ")
      }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device_sengled:generate_test_message("main", capabilities.switch.switch.off())
    },
  }
)

test.register_message_test(
  "manufacturer(sengled) specific clster command(\x06\x00\x00\x00) should be handled",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = {
        mock_device_sengled.id,
        zigbee_test_utils.build_custom_command_id(mock_device_sengled, SENGLED_MFR_SPECIFIC_CLUSTER, SENGLED_MFR_SPECIFIC_COMMAND, SENGLED_MFR_CODE, "   ")
      }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device_sengled:generate_test_message("main", capabilities.switch.switch.on())
    },
  }
)

test.register_message_test(
  "manufacturer(sengled) specific clster command(\x08\x00\x00\x00) should be handled",
  {
    {
      channel = "zigbee",
      direction = "receive",
      message = {
        mock_device_sengled.id,
        zigbee_test_utils.build_custom_command_id(mock_device_sengled, SENGLED_MFR_SPECIFIC_CLUSTER, SENGLED_MFR_SPECIFIC_COMMAND, SENGLED_MFR_CODE, "   ")
      }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device_sengled:generate_test_message("main", capabilities.switch.switch.off())
    },
  }
)

test.register_message_test(
  "Capability command On should be handled",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_device_sengled.id, { capability = "switch", component = "main", command = "on", args = { } } }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device_sengled:generate_test_message("main", capabilities.switch.switch.on({ state_change = true }))
    }
  }
)

test.register_message_test(
  "Capability command Off should be handled",
  {
    {
      channel = "capability",
      direction = "receive",
      message = { mock_device_sengled.id, { capability = "switch", component = "main", command = "off", args = { } } }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device_sengled:generate_test_message("main", capabilities.switch.switch.off({ state_change = true }))
    }
  }
)

test.register_coroutine_test(
  "Capability command setLevel should be handled",
  function()
    test.timer.__create_and_queue_test_time_advance_timer(1, "oneshot")

    test.socket.capability:__queue_receive({mock_device_sengled.id, { capability = "switchLevel", component = "main", command = "setLevel", args = { 0 } }})
    test.socket.capability:__expect_send(mock_device_sengled:generate_test_message("main", capabilities.switch.switch.off({ state_change = true })))
    test.wait_for_events()
    test.mock_time.advance_time(1)
    test.socket.capability:__expect_send(mock_device_sengled:generate_test_message("main", capabilities.switchLevel.level(0)))
    test.wait_for_events()
  end
)

test.register_coroutine_test(
  "Capability command setLevel should be handled",
  function()
    test.timer.__create_and_queue_test_time_advance_timer(1, "oneshot")

    test.socket.capability:__queue_receive({mock_device_sengled.id, { capability = "switchLevel", component = "main", command = "setLevel", args = { 57 } }})
    test.socket.capability:__expect_send(mock_device_sengled:generate_test_message("main", capabilities.switch.switch.on({ state_change = true })))
    test.wait_for_events()
    test.mock_time.advance_time(1)
    test.socket.capability:__expect_send(mock_device_sengled:generate_test_message("main", capabilities.switchLevel.level(57)))
    test.wait_for_events()
  end
)

test.register_coroutine_test(
  "Move command should be handled by centrailite system device",
  function()
    local move_command = Level.server.commands.Move.build_test_rx(mock_device_centralite, Level.types.MoveStepMode.DOWN, 0x00,
                                                                  0x00, 0x00)
    local frm_ctrl = FrameCtrl(0x01)
    move_command.body.zcl_header.frame_ctrl = frm_ctrl
    test.socket.zigbee:__queue_receive({ mock_device_centralite.id, move_command })
    test.socket.capability:__expect_send(mock_device_centralite:generate_test_message("main", capabilities.switch.switch.on()))
    test.socket.capability:__expect_send(mock_device_centralite:generate_test_message("main", capabilities.switchLevel.level(90)))
  end
)

test.register_coroutine_test(
  "Move command should be handled by ikea of sweden device",
  function()
    do
      local move_command = Level.server.commands.Move.build_test_rx(mock_device_ikea, Level.types.MoveStepMode.UP, 0x00,
                                                                  0x00, 0x00)
      local frm_ctrl = FrameCtrl(0x01)
      move_command.body.zcl_header.frame_ctrl = frm_ctrl
      test.socket.zigbee:__queue_receive({ mock_device_ikea.id, move_command })
      test.socket.capability:__expect_send(mock_device_ikea:generate_test_message("main", capabilities.switch.switch.on()))
      test.socket.capability:__expect_send(mock_device_ikea:generate_test_message("main", capabilities.switchLevel.level(100)))
    end
    do
      local move_command = Level.server.commands.Move.build_test_rx(mock_device_ikea, Level.types.MoveStepMode.DOWN, 0x00,
                                                                    0x00, 0x00)
      local frm_ctrl = FrameCtrl(0x01)
      move_command.body.zcl_header.frame_ctrl = frm_ctrl
      test.socket.zigbee:__queue_receive({ mock_device_ikea.id, move_command })
      test.socket.capability:__expect_send(mock_device_ikea:generate_test_message("main", capabilities.switch.switch.on()))
      test.socket.capability:__expect_send(mock_device_ikea:generate_test_message("main", capabilities.switchLevel.level(90)))
    end
  end
)

test.register_coroutine_test(
  "Move with onoff command should be handled by centrailite system device",
  function()
    local move_command = Level.server.commands.MoveWithOnOff.build_test_rx(mock_device_centralite, Level.types.MoveStepMode.DOWN, 0x00,
                                                                  0x00, 0x00)
    local frm_ctrl = FrameCtrl(0x01)
    move_command.body.zcl_header.frame_ctrl = frm_ctrl
    test.socket.zigbee:__queue_receive({ mock_device_centralite.id, move_command })
    test.socket.capability:__expect_send(mock_device_centralite:generate_test_message("main", capabilities.switch.switch.on()))
    test.socket.capability:__expect_send(mock_device_centralite:generate_test_message("main", capabilities.switchLevel.level(100)))
  end
)

test.register_coroutine_test(
  "Move with onoff command should be handled by ikea of sweden device",
  function()
    local move_command = Level.server.commands.MoveWithOnOff.build_test_rx(mock_device_ikea, Level.types.MoveStepMode.UP, 0x00,
                                                                  0x00, 0x00)
    local frm_ctrl = FrameCtrl(0x01)
    move_command.body.zcl_header.frame_ctrl = frm_ctrl
    test.socket.zigbee:__queue_receive({ mock_device_ikea.id, move_command })
    test.socket.capability:__expect_send(mock_device_ikea:generate_test_message("main", capabilities.switch.switch.on()))
    test.socket.capability:__expect_send(mock_device_ikea:generate_test_message("main", capabilities.switchLevel.level(100)))
  end
)

test.register_coroutine_test(
  "Move to level with onoff command should be handled by ikea of sweden device",
  function()
    local move_command = Level.server.commands.MoveToLevelWithOnOff.build_test_rx(mock_device_ikea, 0xff, 0x00,
                                                                  0x00, 0x00)
    local frm_ctrl = FrameCtrl(0x01)
    move_command.body.zcl_header.frame_ctrl = frm_ctrl
    test.socket.zigbee:__queue_receive({ mock_device_ikea.id, move_command })
    test.socket.capability:__expect_send(mock_device_ikea:generate_test_message("main", capabilities.switch.switch.on({ state_change = true })))
    test.socket.capability:__expect_send(mock_device_ikea:generate_test_message("main", capabilities.switch.switch.off()))
  end
)

test.register_coroutine_test(
  "Step command should be handled",
  function()
    local step_command = Level.server.commands.Step.build_test_rx(mock_device_ikea, Level.types.MoveStepMode.UP, 0x00,
                                                                  0x0000, 0x00, 0x00)
    local frm_ctrl = FrameCtrl(0x01)
    step_command.body.zcl_header.frame_ctrl = frm_ctrl
    test.socket.zigbee:__queue_receive({ mock_device_ikea.id, step_command })
    test.socket.capability:__expect_send(mock_device_ikea:generate_test_message("main", capabilities.switch.switch.on()))
    test.socket.capability:__expect_send(mock_device_ikea:generate_test_message("main", capabilities.switchLevel.level(100)))
  end
)

test.register_coroutine_test(
    "lifecycle configure event should configure device (Centralite Systems)",
    function ()
      test.socket.zigbee:__set_channel_ordering("relaxed")
      test.socket.device_lifecycle:__queue_receive({ mock_device_centralite.id, "doConfigure" })
      -- Bind for OnOff -- device only sends us commands
      test.socket.zigbee:__expect_send({
                                        mock_device_centralite.id,
                                        zigbee_test_utils.build_bind_request(mock_device_centralite,
                                                                              zigbee_test_utils.mock_hub_eui,
                                                                              OnOff.ID)
                                      })
      -- Bind for Level -- device only sends us commands
      test.socket.zigbee:__expect_send({
                                        mock_device_centralite.id,
                                        zigbee_test_utils.build_bind_request(mock_device_centralite,
                                                                              zigbee_test_utils.mock_hub_eui,
                                                                              Level.ID)
                                      })
      -- Read, bind, and config reporting for PowerConfiguration
      test.socket.zigbee:__expect_send({
                                        mock_device_centralite.id,
                                        zigbee_test_utils.build_bind_request(mock_device_centralite,
                                                                              zigbee_test_utils.mock_hub_eui,
                                                                              PowerConfiguration.ID)
                                      })
      test.socket.zigbee:__expect_send({
                                        mock_device_centralite.id,
                                        PowerConfiguration.attributes.BatteryVoltage:read(mock_device_centralite)
                                      })
      test.socket.zigbee:__expect_send({
                                        mock_device_centralite.id,
                                        PowerConfiguration.attributes.BatteryVoltage:configure_reporting(mock_device_centralite, 30, 14300, 1)
                                      })
      mock_device_centralite:expect_metadata_update({ provisioning_state = "PROVISIONED" })
    end
)

test.register_coroutine_test(
    "lifecycle configure event should configure device (sengled)",
    function ()
      test.socket.zigbee:__set_channel_ordering("relaxed")
      test.socket.device_lifecycle:__queue_receive({ mock_device_sengled.id, "doConfigure" })

      -- Read, bind, and config reporting for PowerConfiguration
      test.socket.zigbee:__expect_send({
                                        mock_device_sengled.id,
                                        zigbee_test_utils.build_bind_request(mock_device_sengled,
                                                                              zigbee_test_utils.mock_hub_eui,
                                                                              PowerConfiguration.ID)
                                      })
      test.socket.zigbee:__expect_send({
                                        mock_device_sengled.id,
                                        PowerConfiguration.attributes.BatteryPercentageRemaining:read(mock_device_sengled)
                                      })
      test.socket.zigbee:__expect_send({
                                        mock_device_sengled.id,
                                        PowerConfiguration.attributes.BatteryPercentageRemaining:configure_reporting(mock_device_sengled, 30, 14300, 1)
                                      })
      mock_device_sengled:expect_metadata_update({ provisioning_state = "PROVISIONED" })
    end
)

test.run_registered_tests()
