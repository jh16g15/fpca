from PIL import Image


infile = "sim_vga_log.txt"


# VHDL Image Log Format
# One line of text = one line of image
# R G B, R G B, R G B, ...
# VSYNC (marks next frame)
# skip blank lines

frame = -1
x = 0
y = 0

images = []


with open(infile, mode="r") as f:
    for line in f:
        line = line.strip()
        # Handle VSYNC lines by creating a new image array
        if line == "VSYNC":
            print(f"Image done, {y} rows of {x} pixels")
            # print(f"{y_count=}")
            images.append(list())
            # print(f"{images=}")
            frame += 1
            x = 0
            y = 0
        else:
            # ignore blank lines
            if len(line) > 0:
                # remove trailing comma if present to not break line.split
                if line[-1] == ",":
                    line = line[:-1]

                # process line
                x = 0
                
                pixel_arr = line.split(",")
                
                if len(pixel_arr) != 1024:
                    print(f"ERR only {len(pixel_arr)} pixels on line {y}")

                for pixel in pixel_arr:
                    pixel = pixel.strip()
                    
                    channels = pixel.split(" ") 

                    # TODO fix this
                    # if len(channels) != 3:
                    #     continue
                    
                    if y == 0 and x > 1020:
                        print(f"{x} {y} {channels=}")
                    for channel in channels: # R G B
                        # print(f"{channel=}")
                        images[frame].append(int(channel, 16))    # assemble list of pixel data
                    
                    x += 1

                # print(f"Line {y} done, {x_count} pixels")
                y += 1
        


# print(f"DONE {images=}")

# data = bytes([255, 0, 128])
# for i in images:
#     print(f"image {i} length = {len(images[i])}")
print(f"image {0} length = {len(images[0])}")
print(f"image {1} length = {len(images[1])}")
data_arr = bytes(images[0])

im=Image.frombytes("RGB", (1024, 600), data_arr, "raw", "RGB", 0, 1)

im.show()