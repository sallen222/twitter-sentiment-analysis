import re
# Removes hyperlinks and newlines with regex
def transform(text):
    text = re.sub(r'(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])', '', text)
    text = re.sub(r'(\r\n|\r|\n)', '', text)
    return text