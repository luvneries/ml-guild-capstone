FROM python:3.7
ENV APP /app
RUN mkdir $APP
WORKDIR $APP
EXPOSE 8000
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["gunicorn", "-b", "0.0.0.0:8000", "main:app"]