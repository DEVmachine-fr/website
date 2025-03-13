{
  description = "Jekyll 4.2 development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        # Create a Gemfile for Jekyll 4.2
        jekyllGemfile = pkgs.writeText "Gemfile" ''
          source 'https://rubygems.org'

          gem 'jekyll', '~> 4.2.0'
          gem 'webrick'  # Required for Ruby 3.0+

          # Uncomment these lines to add more gems
          # group :jekyll_plugins do
          #   gem 'jekyll-feed'
          #   gem 'jekyll-seo-tag'
          # end
        '';

        # Create a simple _config.yml if needed
        jekyllConfig = pkgs.writeText "_config.yml" ''
          title: My Jekyll Site
          description: Created with Nix
          baseurl: ""
          url: ""

          # Build settings
          markdown: kramdown
          theme: minima
          plugins:
            - jekyll-feed
            - jekyll-seo-tag
        '';
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            # Use Ruby from nixpkgs
            pkgs.ruby_3_1

            # Common dependencies for Jekyll
            pkgs.bundler
            pkgs.libffi
            pkgs.libxml2
            pkgs.libxslt
            pkgs.zlib
            pkgs.pkg-config

            # Useful tools
            pkgs.direnv
            pkgs.nodejs # For JavaScript runtime if needed
          ];

          shellHook = ''
            # Create a Gemfile if it doesn't exist
            if [ ! -f Gemfile ]; then
              echo "Creating Gemfile for Jekyll 4.2..."
              cp ${jekyllGemfile} Gemfile
            fi

            # Create a simple _config.yml if needed
            if [ ! -f _config.yml ] && [ ! -d _site ]; then
              echo "Creating a basic _config.yml..."
              cp ${jekyllConfig} _config.yml
            fi

            # Configure Bundler to install gems locally
            export GEM_HOME="$PWD/.gems"
            export GEM_PATH="$GEM_HOME:$GEM_PATH"
            export PATH="$GEM_HOME/bin:$PATH"
            export BUNDLE_PATH="$GEM_HOME"

            # Install gems if not already installed
            if [ ! -d .gems ]; then
              echo "Installing Jekyll 4.2 and dependencies (this may take a moment)..."
              bundle install
            fi

            echo "Jekyll 4.2 development environment activated!"
            echo "Run 'bundle exec jekyll serve' to start your site locally"
          '';
        };
      }
    );
}
