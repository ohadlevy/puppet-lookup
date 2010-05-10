require 'csv'
module Puppet::Parser::Functions
  newfunction(:lookup, :type => :rvalue) do |args|

    # we parse the precedence here because the best place to specify
    # it would be in site.pp but site.pp is only evaluated at startup
    # so $fqdn etc would have no meaning there, this way it gets evaluated
    # each run and has access to the right variables for that run
    def var_to_fact str
      while str =~ /%\{(.+?)\}/
        fact = lookupvar $1
        raise(Puppet::ParseError, "Unable to found value for #{str}") if fact.nil?
        str.gsub!(/%\{#{$1}\}/, fact)
      end
      str
    end

    lookup_debug = true if lookupvar('lookup_debug?') == true

    # what are we looking for?
    lookup_name = args[0]
    lookup_order = lookupvar('lookup_order') # will always return a string / array (even an empty one)
    # hacky hacky line, but otherwise the value of lookup_order inside puppet will be changed!!
    order = (args[1] || lookup_order).to_a.join("!LoOKUpp!").split("!LoOKUpp!")

    raise Puppet::ParseError, "Unable to find any lookup order make sure you install it in site.pp" if order.nil? or order.empty?

    # expand any variables
    order.map! { |var| var_to_fact var }

    # search through puppet module path and lookup order
    datafiles = Array.new
    env = lookupvar('environment').to_sym
    env_path = Puppet.settings.instance_variable_get(:@values)[env][:modulepath].split(":")
    begin
      order.each do |csv_file|
        env_path.each do |module_path|
          # where our CSV file is located at
          file = "#{module_path}/#{csv_file}.csv"
          debug "scanning if #{file} exists" if lookup_debug
          datafiles << file if File.exists?(file)
        end
      end
    rescue
      raise Puppet::ParseError, "Something went wrong while looking for a datafile for #{lookup_name} - #{$!}"
    end

    debug "Found the following relevant data files: #{datafiles.join(", ")}" if lookup_debug
    # parse our CSV files

    found = false
    result = ""
    datafiles.each do |file|
      begin
        parser.watch_file file
        next if found
        debug "scanning #{file}" if lookup_debug
        result = CSV.read(file).find_all{ |r| r[0] == lookup_name }
        if result.size > 0
          found = true
          result = result.first[1..-1] # result values are in a nested array, removing one layer.
          result.map! { |r| var_to_fact r } # replace values to facts if required.
          debug "Found: #{result} at #{file}" if lookup_debug
        end
      rescue
        raise Puppet::ParseError, "Something went wrong while parsing #{file} - #{$!}"
      end
    end

    if not found or result.size == 0
      raise Puppet::ParseError, "unable to find value for #{lookup_name}"
    else
      return result.size == 1 ? result.to_s : result
    end
  end
end
