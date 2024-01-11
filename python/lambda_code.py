from logging import getLogger

log = getLogger("test")

def lambda_handler(event, context):

   message = 'Hello {} !'.format(event['key1'])
   print(event)
   log.info("Log created")
   log.info(f" event {event}")

   return {

       'message' : message

   }