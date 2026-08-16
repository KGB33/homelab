{ inputs, den, ... }: {
  imports = [
    (inputs.den.namespace "o11y" true)
  ];

  # this line enables den angle brackets syntax in modules.
  _module.args.__findFile = den.lib.__findFile;
}
