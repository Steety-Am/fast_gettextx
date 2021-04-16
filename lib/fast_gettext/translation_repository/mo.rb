require 'fast_gettext/translation_repository/base'
module FastGettext
  module TranslationRepository
     # Responsibility:
    #  - find and store mo files
    #  - provide access to translations in mo files
    class Mo < Base
      def initialize(name,options={})
        # parse all .mo files with the right name, that sit in locale/LC_MESSAGES folders
        find_files_in_locale_folders(File.join('LC_MESSAGES',"#{name}.mo"),options[:path]) do |locale,file|
          @files[locale] = MoFile.new(file)
        end
      end

      def available_locales
        @files.keys
      end

      protected

      def current_translations
        @files[FastGettext.locale] || MoFile.empty
      end
    end
  end
end