service: alexa-skills

provider:
  name: aws
  runtime: go1.x
  memorySize: 128
  region: us-east-1

package:
 exclude:
   - ./**
 include:
   - ./bin/**

functions:
  winner:
    handler: bin/winner
    environment:
      REDIS_HOST: ${redis_host}
      REDIS_PORT: ${redis_port}
    events:
      - alexaSkill: ${the_song_is_skill_id}
      - schedule:
          rate: rate(5 minutes)
          input: '${winner_intent}'
    vpc:
      securityGroupIds:
        - ${security_group_id}
      subnetIds:
        - ${private_subnet_0}
        - ${private_subnet_1}
        - ${private_subnet_2}
  deletekeys:
    handler: bin/deletekeys
    environment:
      REDIS_HOST: ${redis_host}
      REDIS_PORT: ${redis_port}
    events:
      - alexaSkill: ${delete_keys_skill_id}
      - schedule:
          rate: rate(5 minutes)
          input: '${delete_keys_intent}'
    vpc:
      securityGroupIds:
        - ${security_group_id}
      subnetIds:
        - ${private_subnet_0}
        - ${private_subnet_1}
        - ${private_subnet_2}
