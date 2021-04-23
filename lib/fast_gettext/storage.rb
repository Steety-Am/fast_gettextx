module FastGettext
  # Responsibility:
  #  - store data threadsave
  #  - provide error messages when repositories are unconfigured
  #  - accept/reject locales that are set by the user
  module Storage
    class NoTextDomainConfigured < Exception;end

    [:available_locales,:text_domain].each do |method|
      define_method method do
        thread_store(method)
      end
      define_method "#{method}=" do |value|
        write_thread_store(method,value)
      end
    end

    #global, since re-parsing whole folders takes too much time...
    @@translation_repositories={}
    def translation_repositories
      @@translation_repositories
    end

    def text_domain=(new_text_domain)
      write_thread_store(:text_domain,new_text_domain)
    end

    def current_repository
      translation_repositories[text_domain] || NoTextDomainConfigured
    end

    def locale
      thread_store(:locale) || (available_locales||[]).first || 'en'
    end

    def locale=(new_locale)
      new_locale = best_locale_in(new_locale)
      if new_locale
        write_thread_store(:locale,new_locale)
      end
    end

    # for chaining: puts set_locale('xx') == 'xx' ? 'applied' : 'rejected'
    # returns the current locale, not the one that was supplied
    # like locale=(), whoes behavior cannot be changed
    def set_locale(new_locale)
      self.locale = new_locale
      locale
    end

    #Opera: de-DE,de;q=0.9,en;q=0.8
    #Firefox de-de,de;q=0.8,en-us;q=0.5,en;q=0.3
    #IE6/7 de
    #nil if nothing matches
    def best_locale_in(locales)
      locales = locales.to_s.gsub(/\s/,'')

      #split the locale and seperate it into different languages
      #[['de-de','de','0.5'], ['en','0.8'], ...]
      parts = locales.split(',')
      locales = [[]]
      parts.each do |part|
        locales.last << part.split(/;q=/)#add another language or language and weight
        locales += [] if part.length == 2 #if it could be split we are now in a new locale
      end

      locales.sort!(&:last) #sort them by weight which is the last entry
      locales.flatten.each do |candidate|
        candidate = candidate.sub(/^([a-zA-Z]{2})[-_]([a-zA-Z]{2})$/){$1.downcase+'_'+$2.upcase}#de-de -> de_DE
        return candidate if not available_locales or available_locales.include?(candidate)
      end
      return nil#nothing found im sorry :P
    end

    #turn off translation if none was defined to disable all resulting errors
    def silence_errors
      if not self.current_repository or self.current_repository == NoTextDomainConfigured
        require 'fast_gettext/translation_repository/base'
        translation_repositories[text_domain] = TranslationRepository::Base.new('x')
      end
    end

    private

    def thread_store(key)
      Thread.current["FastGettext.#{key}"]
    end

    def write_thread_store(key,value)
      Thread.current["FastGettext.#{key}"]=value
    end
  end
end