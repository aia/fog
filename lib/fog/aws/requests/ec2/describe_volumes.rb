unless Fog.mocking?

  module Fog
    module AWS
      class EC2

        # Describe all or specified volumes.
        #
        # ==== Parameters
        # * volume_id<~Array> - List of volumes to describe, defaults to all
        #
        # ==== Returns
        # * response<~Fog::AWS::Response>:
        #   * body<~Hash>:
        #     * 'volumeSet'<~Array>:
        #       * 'availabilityZone'<~String> - Availability zone for volume
        #       * 'createTime'<~Time> - Timestamp for creation
        #       * 'size'<~Integer> - Size in GiBs for volume
        #       * 'snapshotId'<~String> - Snapshot volume was created from, if any
        #       * 'status'<~String> - State of volume
        #       * 'volumeId'<~String> - Reference to volume
        #       * 'attachmentSet'<~Array>:
        #         * 'attachmentTime'<~Time> - Timestamp for attachment
        #         * 'device'<~String> - How value is exposed to instance
        #         * 'instanceId'<~String> - Reference to attached instance
        #         * 'status'<~String> - Attachment state
        #         * 'volumeId'<~String> - Reference to volume
        def describe_volumes(volume_id = [])
          params = indexed_params('VolumeId', volume_id)
          request({
            'Action' => 'DescribeVolumes'
          }.merge!(params), Fog::Parsers::AWS::EC2::DescribeVolumes.new)
        end

      end
    end
  end

else

  module Fog
    module AWS
      class EC2

        def describe_volumes(volume_id = [])
          volume_id = [*volume_id]
          response = Fog::Response.new
          if volume_id != []
            volume_set = @data['volumeSet'].select {|volume| volume_id.include?(volume['volumeId'])}
          else
            volume_set = @data['volumeSet']
          end

          volume_set.each do |volume|
            case volume['status']
            when 'creating'
              if Time.now - volume['createTime'] > 2
                volume['status'] = 'available'
              end
            when 'deleting'
              if Time.now - @data[:deleted_at][volume['volumeId']] > 2
                @data[:deleted_at].delete(volume['volumeId'])
                volume_set.delete(volume)
              end
            end
          end

          if volume_id.length == 0 || volume_id.length == volume_set.length
            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'volumeSet' => volume_set
            }
          else
            response.status = 400
          end
          response
        end

      end
    end
  end

end
