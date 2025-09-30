# Build stage
FROM golang:1.25 AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
COPY crush.json ./
# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o crush .

# Final stage
FROM alpine:3.18

# Install ca-certificates for HTTPS requests and git for version control
RUN apk --no-cache add ca-certificates git

RUN mkdir -p /src
VOLUME /src

WORKDIR /root/

# Copy the binary from builder stage
COPY --from=builder /app/crush .

# Create necessary directories
RUN mkdir -p .config/crush .local/share/crush
COPY crush.json .config/crush
# Expose port for profiling (optional)
EXPOSE 6060

# Run the application
ENTRYPOINT ["/bin/sh"]
