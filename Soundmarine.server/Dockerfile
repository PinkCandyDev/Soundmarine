FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
RUN apt-get update && apt-get install -y libgssapi-krb5-2 && rm -rf /var/lib/apt/lists/*
USER $APP_UID
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["Soundmarine.server/Soundmarine.server.csproj", "Soundmarine.server/"]
COPY ["Soundmarine.lib/Soundmarine.lib.csproj", "Soundmarine.lib/"]
RUN dotnet restore "Soundmarine.server/Soundmarine.server.csproj"
COPY . .
WORKDIR "/src/Soundmarine.server"
RUN dotnet build "./Soundmarine.server.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./Soundmarine.server.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM mwader/static-ffmpeg:7.1 AS ffmpeg

FROM base AS final
WORKDIR /app
COPY --from=ffmpeg /ffmpeg /usr/local/bin/ffmpeg
COPY --from=ffmpeg /ffprobe /usr/local/bin/ffprobe
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Soundmarine.server.dll"]