---
title: "About"
date: 2025-11-25T20:55:31+01:00
draft: false

showDate : false
showDateOnlyInArticle : false
showDateUpdated : false
showHeadingAnchors : false
showPagination : false
showReadingTime : false
showTableOfContents : true
showRelatedContent : false
showTaxonomies : false
showWordCount : false
showSummary : false
sharingLinks : false
showEdit: false
showViews: false
showLikes: false
showAuthor: true
layoutBackgroundHeaderSpace: false

---

{{< lead >}}
<<If you can't explain it simply, you don't understand it well enough.>> - Albert Einstein
{{< /lead >}}

I'm a software engineer deeply focused on **medical device development**. My expertise is in firmware, real-time systems and human-machine interfaces (HMIs) for devices that diagnose, stimulate and, increasingly, live inside people. In this field, software has to be correct long before it's allowed to be clever.

I hold a **BEng in Telecommunication Technologies and Services Engineering** from the Polytechnic University of Catalonia (UPC), where I majored in electronic systems and wrote my thesis on smart, low-cost motion controllers that classify movement with TinyML. Later, alongside my work at Neuroelectrics, I earned an **MSc in Artificial Intelligence** with Distinction from the University of London, majoring in data science. My thesis there used convolutional neural networks to identify ancient Roman coins.

Since 2019 my work has taken me from wearables on the scalp to implants inside the body. Along the way I've worked on ARM Cortex-M firmware, real-time and safety-oriented RTOSes, ASIC interfaces, BLE and Wi-Fi links, Qt/C++ applications used in clinics and research labs, and the **IEC 62304** and **ISO 14971** work that turns all of it into a device regulators will accept. This page is the long version of that story.

## University: early prototypes {#university}

During my last year studying telecommunications engineering at UPC, I worked on two projects outside the classroom that relate to life sciences and biomedical data acquisition and monitorization. Both combined custom hardware, firmware and data, which is still the mix I work in today.

### Sensory seating prototype {#sensory-seating}

<p class="about-role">SPTbcn · Electronics Engineer & Project Manager Trainee · 2019</p>

At [SPTbcn](https://www.linkedin.com/company/sptbcn/) (Sensorial Processing Technologies) I built a prototype chair for a healthcare-oriented sensory seating system. The chair could tell when the person sitting in it was seated incorrectly and let them know through vibration feedback, and it picked up their biosignals directly from the seat.

- **Signal processing.** I prototyped DSP-based signal processing and communications on a TI C674x DSP.
- **Biosignals.** I developed the acquisition system on a BITalino board, monitoring ECG and EDA over BLE.
- **Project management.** I broke the work down into tasks and followed them up across a seven-member team.

### QAireUPC {#qaireupc}

<p class="about-role">UPC · Research Assistant · 2020</p>

<div class="figure-aside">

{{< figure src="img/qaire.jpg" alt="A QAireUPC poster and air-quality monitor in a university electronics lab" caption="QAireUPC in one of the university's labs." >}}

</div>

During the COVID-19 outbreak I joined UPC's [Department of Electronic Engineering](https://eel.upc.edu/en) as a research assistant to design the first prototype for QAireUPC, a system to track congestion and air quality in the university's laboratories. I worked across the whole stack:

- **Hardware and firmware.** PCB design and firmware for ESP32-based sensor nodes measuring CO₂, humidity and temperature.
- **Device fleet.** An AWS IoT fleet to connect and manage the nodes.
- **Real-time data.** Streaming from the labs to the cloud platform that logged and monitored them.

It was a complete system, from a circuit board on a lab bench to a live dashboard in the cloud.

## Neuroelectrics: non-invasive neurotech {#neuroelectrics}

I joined [Neuroelectrics](https://www.neuroelectrics.com/) in Barcelona as a junior software engineer at the end of 2019, while finishing my degree, and stayed for over five years. The company builds wireless, non-invasive systems that record the brain's electrical activity (EEG) and stimulate it (tES). As in most startups, being a "software engineer" there meant a bit of everything: microcontroller firmware, radio drivers, desktop and tablet applications, cloud backends, and the regulatory documentation that ties them together.

{{< carousel images="{img/img_work_ne_01.webp,img/img_work_ne_02.webp,img/img_work_ne_03.webp,img/img_work_ne_04.webp}" aspectRatio="4-3" >}}

### Starstim Home {#starstim-home}

<p class="about-role">Junior Software Engineer · 2019&nbsp;–&nbsp;2022 · <span class="device-class">Class IIb</span></p>

My work at Neuroelectrics started with **Starstim Home**, a Class IIb tACS neurostimulator for personalized, at-home treatment of Major Depressive Disorder. Treatment at home means the system has to be safe in a patient's living room, not only in a clinic.

- **Patient tablet app.** I wrote a C# wrapper that synchronized customers' behavioral tasks with the Qt 5/QML app patients used on their tablets.
- **Research collaborations.** I helped international partners such as EPFL, Oxford and Bielefeld integrate Azure/SQL cloud backends for their behavioral-task data.
- **Electrode placement.** I developed Python tools to position electrodes on 3D scalp models, bridging research outputs and the commercial software.
- **Clinical studies.** For US FDA clinical studies, I built Python/PyQt desktop apps, test-driven with Behave and Gherkin, to manage and randomize placebo treatments.

### Starstim tDCS {#starstim-tdcs}

<p class="about-role">Junior Software Engineer · 2020&nbsp;–&nbsp;2022 · <span class="device-class">Class IIb</span></p>

As a junior engineer I also worked on **Starstim tDCS**, a CE-marked Class IIb transcranial direct current stimulation system for acute ischemic stroke, post-stroke aphasia and chronic neuropathic pain. I carried out the design change from a previously commercialized device, including firmware improvements and a complete UI/UX redesign of the HMI.

- **Wireless reliability.** I cut packet loss six-fold over 24-hour sessions by reworking the WF121 radio drivers (BASIC), the SAM4S firmware (C, ASF) and the Windows networking layer (C/C++, WLAN API, C++/WinRT).
- **Impedance accuracy.** I improved the firmware's measurement algorithms in C/C++, backed by simulations and circuit analysis, making electrode impedance measurements up to 21% more accurate. Impedance is how a stimulator knows each electrode is in good contact with the scalp, which matters for both comfort and safety.
- **The clinical application.** As part of that redesign, I moved it from Qt 5 to Qt 6 and from MinGW to MSVC.

### NIC Akkadian {#nic-akkadian}

<p class="about-role">Software Engineer · 2022&nbsp;–&nbsp;2024 · <span class="device-class">Class IIb</span></p>

In 2022 I moved on to **NIC Akkadian**, a Class IIb tACS/tDCS neurostimulator for refractory focal epilepsy, a form of the disease that doesn't respond to medication. It was granted FDA Breakthrough Device designation. I developed both its firmware and its HMI.

- **Firmware.** I wrote bare-metal C firmware and low-level drivers (ASF) for its SAM4S, a Cortex-M4 microcontroller.
- **HMI.** I designed and implemented the cross-platform Qt 6/QML application (C++, CMake) for Windows, macOS and iOS that controls the device, configures treatments and shows telemetry.
- **Mobile.** I planned the software architecture for a cross-platform iOS/Android app.
- **Documentation.** I led the software lifecycle documents (SRS, SDS and FMEA) under IEC 62304 and ISO 14971.

{{< figure src="img/img_work_ne_05.png" alt="The NIC application showing a stimulation montage on a laptop and a 3D brain model on a tablet" caption="NIC, Neuroelectrics' application for configuring and visualizing tES treatments, on desktop and tablet." >}}

### Enobio Dx {#enobio-dx}

<p class="about-role">Software Engineer & Scrum Master · 2024&nbsp;–&nbsp;2025 · <span class="device-class">Class IIa</span></p>

<div class="figure-aside">

{{< figure src="img/img_work_ne_06.jpg" alt="The Enobio Dx EEG cap and its wireless amplifier, seen from behind" >}}

</div>

For my last year at Neuroelectrics I led embedded development for **Enobio Dx**, a wireless 8, 20 and 32-channel EEG system, CE-marked as a Class IIa device and FDA 510(k) cleared for clinical diagnosis and long-term monitoring. Most of that work was optimization:

- **Battery life from 13 to 24 hours** in Holter mode, by optimizing the low-power drivers.
- **2.8× faster EEG processing** on 24-hour recordings, by optimizing the multi-gigabyte C++ pipeline that converts raw binary data to EDF.
- **A replacement radio** for an obsolete Bluetooth/Wi-Fi module, prototyped on the Silicon Labs RS9116 (C, FreeRTOS) and the Lantronix xPico240 (C, RESTful API).

It's also when I became **Scrum Master** for a team of five engineers, a role I've kept ever since. Keeping a cross-functional team's work visible, unblocked and predictable turns out to have a lot in common with keeping firmware that way.

## INBRAIN: implantable neurotech {#inbrain}

<p class="about-role">Embedded Software Engineer & Scrum Master · 2025&nbsp;–&nbsp;present · <span class="device-class">Class III</span></p>

In March 2025 I joined [INBRAIN Neuroelectronics](https://inbrain-neuroelectronics.com/), which builds graphene-based brain-computer interfaces, and the devices I work on moved from the scalp to inside the body. I develop safety-critical firmware for **BCI-Tx**, a Class III implantable adaptive deep brain stimulation (DBS) system for Parkinson's disease with a 200-channel graphene interface, and for a **vagus nerve stimulation (VNS) platform** for bioelectronic medicine.

{{< figure src="img/img_work_ibn_02.jpg" alt="Render of a brain with cortical and subcortical interfaces connected to an implanted neural controller" caption="INBRAIN's brain-computer interface: cortical and subcortical interfaces connected to an implanted neural controller." >}}

Class III changes how you engineer. An implant can't be unplugged or swapped out when something goes wrong, so safety has to be designed into the architecture rather than tested in at the end. My work covers:

- **Firmware.** I implemented the Cortex-M33 firmware and its low-level drivers in C, on FreeRTOS, with safety mechanisms defined under IEC 62304 and ISO 14971.
- **Certified foundations.** I migrated the codebase to a certified toolchain (Keil MDK) and a safety-oriented RTOS (SafeRTOS), because in a Class III device the compiler and the kernel are part of the safety argument too.
- **Secure BLE.** I designed the BLE GATT interface on Apache NimBLE for secure communication.
- **CI/CD.** I automated the unit tests (GoogleTest, GoogleMock, FFF) with Jenkins and Bitbucket pipelines.

<div class="carousel-contain">

{{< carousel images="{img/img_work_ibn_01.png,img/img_work_ibn_03.png,img/img_work_ibn_04.png}" aspectRatio="4-3" >}}

</div>

I'm also Scrum Master for a team of ten engineers. I run the sprint meetings and coordinate across disciplines, keeping them all aligned on the same goals.

## How I work {#how-i-work}

The through-line in all of this is rigor, clarity and long-term reliability. In practice:

- **Safety is designed in, not tested in.** ISO 14971 risk analysis should shape the firmware architecture and its safety mechanisms from the first diagram, not be written up after the code exists.
- **Traceability, end to end.** Every requirement should lead to a design decision, a verification test and, where it applies, a risk control. When that chain holds, audits are uneventful and changes are safe to make.
- **Foundations you can defend.** Certified toolchains, safety-oriented RTOSes, reproducible builds and test-driven tools aren't glamorous, but they're what lets a device get certified and then be maintained for years.
- **Explain it simply.** A design isn't finished until I can explain it to a clinician, a regulator or a new engineer on the team. The quote at the top of this page isn't decoration.

## Beyond the day job {#beyond-work}

I contribute upstream to the open-source embedded tools I depend on, with fixes to Zephyr RTOS, Nordic's nrfx drivers and Apache NimBLE.

This blog is where I write about embedded engineering, medical device development, applied AI, system architecture and tools, and the hard-earned lessons from shipping software in regulated, safety-critical domains. For the condensed version of all of the above, see my [resume]({{< relref "/about/resume" >}}).
