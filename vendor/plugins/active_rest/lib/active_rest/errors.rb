module ActiveRest
  class ResourceNotFound < ActiveRecord::RecordNotFound
  end

  class ClientError < Exception
  end

  class ServerError < Exception
  end
  
  class NoCredentialsError < Exception
  end

  class AuthorizationRejectedError < Exception
  end
end

