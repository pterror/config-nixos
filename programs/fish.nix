{
  enable = true;
  interactiveShellInit = ''
    abbr gl "git log --format='format:%Cblue%h %C(yellow)%aN %Cgreen%>(14)%ar %Creset%s'"
  '';
}
