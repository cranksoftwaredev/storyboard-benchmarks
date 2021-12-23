/*
 * Copyright 2007, Crank Software Inc. All Rights Reserved.
 *
 * For more information email info@cranksoftware.com.
 */

/**
 * This is a sample application that will generate IO messages
 * and inject them into the GRE application.
 *
 * It uses IO interface API to send the events
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/time.h>

#include <gre/greio.h>


unsigned int verticalConstraint = 100;
unsigned int horizontalConstraint = 100;
unsigned int scale = 1;
unsigned int panorama1X = 0;
unsigned int panorama2X = 0;

float sampleFPS = 0;
unsigned int sampleDuration = 500; //frames are incremented on each render, sampleDuration says how many milliseconds to average that data over before displaying
uint64_t lastSampledTime = 0;
unsigned int sampleFrames = 0;
unsigned int startTime;

gre_io_t                 *send_handle;
gre_io_t                 *recv_handle;


uint64_t getTime()
{
	struct timeval tv;

	gettimeofday(&tv, NULL);
	return ((tv.tv_sec * 1000) + tv.tv_usec);
}

int tweenValues()
{
	//calulate see-saw values
	float stretchTime = 0;
	float oneSecMilli = 0;
	float oneSecDuration = 0;
	float panTime;
	unsigned int twoSecMilli;
	float twoSecPos;


	stretchTime =  getTime() % 2000;
	oneSecMilli = getTime() % 1000;
	if (oneSecMilli < 1){
		oneSecMilli = 1;
	}

	//printf("oneSecMilli : %f\n",oneSecMilli);

	if (stretchTime < 1000) {
		oneSecDuration = 0+(oneSecMilli/1000);
	}else{
		oneSecDuration = 1-(oneSecMilli/1000);
	}

	//printf("oneSecDuration : %f\n",oneSecDuration);

	verticalConstraint = 100+(oneSecDuration*200);
	horizontalConstraint = 100+(oneSecDuration*350);
	scale = 1+(oneSecDuration*4);

	//printf("verticalConstraint : %d horizontalConstraint : %d\n",verticalConstraint,horizontalConstraint);

	//calculate panorama
	panTime = getTime() % 4000;
	twoSecMilli = getTime() % 2000;
	if (twoSecMilli< 1){
		twoSecMilli = 1;
	}
	twoSecPos = (twoSecMilli/2000)*1000;

	if (panTime < 2000) {
		panorama1X = 0-twoSecPos;
		panorama2X = 1000-twoSecPos;
	}else{
		panorama1X = 1000-twoSecPos;
		panorama2X = 0-twoSecPos;
	}

	return 1;
}

int px(int val)
{
	return val+50;
}

int padMore(int val)
{
	return (val+5);
}

int  padLess(int val)
{
	return (val-10);
}



int executeBindings()
{
	int ret = 0;
	gre_io_serialized_data_t *md_buffer = NULL;
	uint32_t value = 0;
	int middleHorizW, middleVertH;
	uint32_t starsize;


	//FPS
//
//    ret = gre_io_add_mdata(&md_buffer, "fps", "1s0", &sampleFPS, sizeof(uint32_t));
//	if(ret == -1){
//		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
//		return(-1);
//	}

	//Banner
	ret = gre_io_add_mdata(&md_buffer, "banner_layer.banner1.grd_x", "4u1", &panorama1X, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

    ret = gre_io_add_mdata(&md_buffer, "banner_layer.banner2.grd_x", "4u1", &panorama2X, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	//Boxes
	middleHorizW = 1000-(horizontalConstraint*2);
	middleVertH = 700-(verticalConstraint*2);

    gre_io_send_mdata(send_handle, md_buffer);
    gre_io_zero_buffer(md_buffer);
    md_buffer = NULL;

	//Box 1
	value = 0;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder1.grd_x", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = 0;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder1.grd_y", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = horizontalConstraint;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder1.grd_width", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = verticalConstraint;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder1.grd_height", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	//Box 2
	value = padMore(horizontalConstraint);
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder2.grd_x", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = 0;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder2.grd_y", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = padLess(middleHorizW);
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder2.grd_width", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = verticalConstraint;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder2.grd_height", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}


	//Box 3
	value = 1000-horizontalConstraint;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder3.grd_x", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = 0;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder3.grd_y", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = horizontalConstraint;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder3.grd_width", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = verticalConstraint;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder3.grd_height", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	   gre_io_send_mdata(send_handle, md_buffer);
	    gre_io_zero_buffer(md_buffer);
	    md_buffer = NULL;


	//Box 4
	value = 0;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder4.grd_x", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = padMore(verticalConstraint);
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder4.grd_y", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = horizontalConstraint;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder4.grd_width", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = padLess(middleVertH);
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder4.grd_height", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	//Box 5
	value = padMore(horizontalConstraint);
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder5.grd_x", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = padMore(verticalConstraint);
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder5.grd_y", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = padLess(middleHorizW);
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder5.grd_width", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = padLess(middleVertH);
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder5.grd_height", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	//Box 6
	value = 1000-horizontalConstraint;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder6.grd_x", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = padMore(verticalConstraint);
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder6.grd_y", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = horizontalConstraint;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder6.grd_width", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

    gre_io_send_mdata(send_handle, md_buffer);
    gre_io_zero_buffer(md_buffer);
    md_buffer = NULL;

	value = padLess(middleVertH);
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder6.grd_height", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	//Box 7
	value = 0;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder7.grd_x", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = 700-verticalConstraint;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder7.grd_y", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = horizontalConstraint;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder7.grd_width", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = verticalConstraint;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder7.grd_height", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	//Box 8
	value = padMore(horizontalConstraint);
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder8.grd_x", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = 700-verticalConstraint;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder8.grd_y", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = padLess(middleHorizW);
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder8.grd_width", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = verticalConstraint;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder8.grd_height", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}


	//Box 9
	value = 1000-horizontalConstraint;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder9.grd_x", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = 700-verticalConstraint;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder9.grd_y", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = horizontalConstraint;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder9.grd_width", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = verticalConstraint;
    ret = gre_io_add_mdata(&md_buffer, "box_layer.holder9.grd_height", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}


    gre_io_send_mdata(send_handle, md_buffer);
    gre_io_zero_buffer(md_buffer);
    md_buffer = NULL;

    starsize = 100*scale;

    //Star 1
	value = 500-(starsize/2);
    ret = gre_io_add_mdata(&md_buffer, "star_layer.star1.grd_x", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = 250-(starsize/2);
    ret = gre_io_add_mdata(&md_buffer, "star_layer.star1.grd_y", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = starsize;
    ret = gre_io_add_mdata(&md_buffer, "star_layer.star1.grd_width", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = starsize;
    ret = gre_io_add_mdata(&md_buffer, "star_layer.star1.grd_height", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

    //Star 2
	value = 500-(starsize/2);
    ret = gre_io_add_mdata(&md_buffer, "star_layer.star2.grd_x", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = 450-(starsize/2);
    ret = gre_io_add_mdata(&md_buffer, "star_layer.star2.grd_y", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = starsize;
    ret = gre_io_add_mdata(&md_buffer, "star_layer.star2.grd_width", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = starsize;
    ret = gre_io_add_mdata(&md_buffer, "star_layer.star2.grd_height", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

    gre_io_send_mdata(send_handle, md_buffer);
    gre_io_zero_buffer(md_buffer);
    md_buffer = NULL;

    starsize = 600-starsize;

    //Star 3
	value = 400-(starsize/2);
    ret = gre_io_add_mdata(&md_buffer, "star_layer.star3.grd_x", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = 350-(starsize/2);
    ret = gre_io_add_mdata(&md_buffer, "star_layer.star3.grd_y", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = starsize;
    ret = gre_io_add_mdata(&md_buffer, "star_layer.star3.grd_width", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = starsize;
    ret = gre_io_add_mdata(&md_buffer, "star_layer.star3.grd_height", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

    //Star 4
	value = 600-(starsize/2);
    ret = gre_io_add_mdata(&md_buffer, "star_layer.star4.grd_x", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = 350-(starsize/2);
    ret = gre_io_add_mdata(&md_buffer, "star_layer.star4.grd_y", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = starsize;
    ret = gre_io_add_mdata(&md_buffer, "star_layer.star4.grd_width", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

	value = starsize;
    ret = gre_io_add_mdata(&md_buffer, "star_layer.star4.grd_height", "4u1", &value, sizeof(uint32_t));
	if(ret == -1){
		fprintf(stderr,"Failed to add data to gre_io_add_mdata\n");
		return(-1);
	}

    gre_io_send_mdata(send_handle, md_buffer);
    gre_io_zero_buffer(md_buffer);
    md_buffer = NULL;

    return 1;
}

int  calculateFramerate()
{
	static uint32_t sampleFrames;
	uint64_t diff;
	float rawFPS;

	diff = getTime() - lastSampledTime;
	sampleFrames++;

	if (diff >= sampleDuration){
		rawFPS = sampleFrames/(diff/1000);
		sampleFPS = (rawFPS*100)/100;  //format as XX.XX
		sampleFrames = 0;
		lastSampledTime = getTime();
		//printf("FPS = %0.2f\n",sampleFPS);
	}
	return 1;
}

int main(int argc, char **argv) {
    gre_io_serialized_data_t      *buffer = NULL;
    gre_io_serialized_data_t      *sbuffer = NULL;
    int ret;

    send_handle = gre_io_open("FramrateTest", GRE_IO_TYPE_WRONLY);
    if(send_handle == NULL) {
        printf("Can't open send handle [%s]\n", argv[1]);
        return 0;
    }

    recv_handle = gre_io_open("FramerateEngine", GRE_IO_TYPE_RDONLY);
    if(recv_handle == NULL) {
        printf("Can't open recv handle\n");
        return 0;
    }
    startTime = getTime();

    sbuffer =  gre_io_serialize(NULL,NULL, "StartFramerateTest", 0,0,0);
    gre_io_send(send_handle, sbuffer);
    gre_io_zero_buffer(sbuffer);

    while(1) {
        ret = gre_io_receive(recv_handle, &buffer);
        if(ret < 0) {
            printf("Problem receiving data on channel\n");
            break;
        }

        sbuffer =  gre_io_serialize(NULL,NULL, "HoldScreen", 0,0,0);
        gre_io_send(send_handle, sbuffer);
        gre_io_zero_buffer(sbuffer);

		calculateFramerate();
		tweenValues();
		ret = executeBindings();
	    if(ret == -1){
	    	fprintf(stderr,"Failed executeBindings()\n");
	    	return(-1);
	    }

	    sbuffer =  gre_io_serialize(NULL,NULL, "RefreshScreen", 0,0,0);
	    gre_io_send(send_handle, sbuffer);
	    gre_io_zero_buffer(sbuffer);

    }
    return 1;

}
