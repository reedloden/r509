require 'openssl'

module R509
	class Cert
		attr_reader :cert, :san_names, :key
		def initialize(*args)
			@san_names = nil
			@extensions = nil
			@cert = nil
			@key = nil
			case args.size
				when 0 then raise ArgumentError, 'Too few args. 1-2 (cert,key)'
				when 1
					parse_certificate(args[0])
				when 2
					parse_certificate(args[0])
					@key = OpenSSL::PKey::RSA.new args[1]
					#we can't use verify here because verify does not do what it does for CSR
					if !(@cert.public_key.to_s == @key.public_key.to_s) then
						raise ArgumentError, 'Key does not match cert.'
					end
				else
					raise ArgumentError, 'Too many args. Max 2 (cert,key)'
			end
		end

		def to_pem
			if(@cert.kind_of?(OpenSSL::X509::Certificate)) then
				return @cert.to_pem.chomp
			end
		end

		alias :to_s :to_pem

		def to_der
			if(@cert.kind_of?(OpenSSL::X509::Certificate)) then
				return @cert.to_der
			end
		end

		def not_before
			@cert.not_before
		end

		def not_after
			@cert.not_after
		end

		def public_key
			@cert.public_key
		end

		def issuer
			@cert.issuer
		end

		def subject
			@cert.subject
		end

		def bit_strength
			if !@cert.nil?
				#cast to int, convert to binary, count size
				@cert.public_key.n.to_i.to_s(2).size
			end
		end

		def write_pem(filename)
			File.open(filename, 'w') {|f| f.write(@cert.to_pem) }
		end

		def write_der(filename)
			File.open(filename, 'w') {|f| f.write(@cert.to_der) }
		end

		def extensions
			parsed_extensions = Hash.new
			@cert.extensions.to_a.each { |extension| 
				extension = extension.to_a
				if(!parsed_extensions[extension[0]].kind_of?(Array)) then
					parsed_extensions[extension[0]] = []
				end
				hash = {'value' => extension[1], 'critical' => extension[2]}
				parsed_extensions[extension[0]].push hash
			}
			parsed_extensions
		end

		private
		#takes OpenSSL::X509::Extension object
		def parse_san_extension(extension)
			san_string = extension.to_a[1]
			stripped = san_string.split(',').map{ |name| name.gsub(/DNS:/,'').strip }
			@san_names = stripped
		end

		def parse_certificate(cert)
			@cert = OpenSSL::X509::Certificate.new cert
			@cert.extensions.to_a.each { |extension| 
				if (extension.to_a[0] == 'subjectAltName') then
					parse_san_extension(extension)
				end
			}
		end

	end
end