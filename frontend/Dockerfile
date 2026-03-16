# ECR Public Gallery mirror - multi-arch, no Docker Hub dependency
FROM public.ecr.aws/nginx/nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 3000
