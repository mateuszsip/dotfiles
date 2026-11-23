-- Define terminal tag to style them uniformly
hl.window_rule({ match = { class = "(Alacritty|com.mitchellh.ghostty)" }, tag = "+terminal" })
hl.window_rule({ match = { tag = "terminal" }, tag = "-default-opacity" })
hl.window_rule({ match = { tag = "terminal" }, opacity = "0.985 0.96" })
