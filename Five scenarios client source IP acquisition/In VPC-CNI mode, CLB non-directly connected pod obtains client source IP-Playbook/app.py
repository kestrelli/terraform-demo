from flask import Flask, request, jsonify
import logging

# 配置日志记录
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('app.log')
    ]
)

app = Flask(__name__)

@app.route('/', methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH'])
def handle_request():
    """处理所有HTTP方法请求，打印并返回请求头"""
    # 获取所有请求头
    headers = dict(request.headers)
    
    # 打印请求头到控制台和日志文件
    logging.info("Received request with headers:")
    for header, value in headers.items():
        logging.info(f"{header}: {value}")
    
    # 返回JSON格式的请求头
    return jsonify({
        "message": "Here are your request headers",
        "headers": headers,
        "method": request.method
	
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)