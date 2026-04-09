{ hrir ? "/home/me/.config/pipewire/hrir/ooyh0.wav", ... }:
# Virtual 7.1 surround sink using HeSuVi HRTF convolution
# WAV file must be manually placed at the path above (default: ~/.config/pipewire/hrir/ooyh0.wav)
# Download from: https://mega.nz/folder/zPx2jAxK#icrUEYHI6St-7m8nUgqcrg
''
context.modules = [
  { name = libpipewire-module-filter-chain
    args = {
      node.description = "Headphone Surround Virtualizer"
      media.name       = "Headphone Surround Virtualizer"
      filter.graph = {
        nodes = [
          # FL
          { type = builtin label = convolver name = conv_fl_l config = { filename = "${hrir}" channel =  0 } }
          { type = builtin label = convolver name = conv_fl_r config = { filename = "${hrir}" channel =  1 } }
          # FR
          { type = builtin label = convolver name = conv_fr_l config = { filename = "${hrir}" channel =  2 } }
          { type = builtin label = convolver name = conv_fr_r config = { filename = "${hrir}" channel =  3 } }
          # FC
          { type = builtin label = convolver name = conv_fc_l config = { filename = "${hrir}" channel =  4 } }
          { type = builtin label = convolver name = conv_fc_r config = { filename = "${hrir}" channel =  5 } }
          # RL
          { type = builtin label = convolver name = conv_rl_l config = { filename = "${hrir}" channel =  6 } }
          { type = builtin label = convolver name = conv_rl_r config = { filename = "${hrir}" channel =  7 } }
          # RR
          { type = builtin label = convolver name = conv_rr_l config = { filename = "${hrir}" channel =  8 } }
          { type = builtin label = convolver name = conv_rr_r config = { filename = "${hrir}" channel =  9 } }
          # SL
          { type = builtin label = convolver name = conv_sl_l config = { filename = "${hrir}" channel = 10 } }
          { type = builtin label = convolver name = conv_sl_r config = { filename = "${hrir}" channel = 11 } }
          # SR
          { type = builtin label = convolver name = conv_sr_l config = { filename = "${hrir}" channel = 12 } }
          { type = builtin label = convolver name = conv_sr_r config = { filename = "${hrir}" channel = 13 } }

          # Mix all left-ear signals together
          { type = builtin label = mixer name = mix_l config = { n_inputs = 7 } }
          # Mix all right-ear signals together
          { type = builtin label = mixer name = mix_r config = { n_inputs = 7 } }
        ]
        links = [
          { output = "conv_fl_l:Out" input = "mix_l:In 1" }
          { output = "conv_fr_l:Out" input = "mix_l:In 2" }
          { output = "conv_fc_l:Out" input = "mix_l:In 3" }
          { output = "conv_rl_l:Out" input = "mix_l:In 4" }
          { output = "conv_rr_l:Out" input = "mix_l:In 5" }
          { output = "conv_sl_l:Out" input = "mix_l:In 6" }
          { output = "conv_sr_l:Out" input = "mix_l:In 7" }

          { output = "conv_fl_r:Out" input = "mix_r:In 1" }
          { output = "conv_fr_r:Out" input = "mix_r:In 2" }
          { output = "conv_fc_r:Out" input = "mix_r:In 3" }
          { output = "conv_rl_r:Out" input = "mix_r:In 4" }
          { output = "conv_rr_r:Out" input = "mix_r:In 5" }
          { output = "conv_sl_r:Out" input = "mix_r:In 6" }
          { output = "conv_sr_r:Out" input = "mix_r:In 7" }
        ]
        inputs  = [ "conv_fl_l:In" "conv_fl_r:In"
                    "conv_fr_l:In" "conv_fr_r:In"
                    "conv_fc_l:In" "conv_fc_r:In"
                    "conv_rl_l:In" "conv_rl_r:In"
                    "conv_rr_l:In" "conv_rr_r:In"
                    "conv_sl_l:In" "conv_sl_r:In"
                    "conv_sr_l:In" "conv_sr_r:In" ]
        outputs = [ "mix_l:Out" "mix_r:Out" ]
      }
      capture.props = {
        node.name      = "effect_input.hesuvi"
        media.class    = Audio/Sink
        audio.channels = 7
        audio.position = [ FL FR FC RL RR SL SR ]
      }
      playback.props = {
        node.name      = "effect_output.hesuvi"
        media.class    = Audio/Source
        audio.channels = 2
        audio.position = [ FL FR ]
      }
    }
  }
]
''
