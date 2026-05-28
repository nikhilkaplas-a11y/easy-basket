const data = {


dsa:{

title:
"DSA Mastery Program",

description:
"Master Data Structures and Algorithms from beginner to advanced level. This program focuses on problem solving, coding interview preparation, competitive programming concepts, and real-world algorithmic thinking. Students will learn optimized coding techniques and build strong logical foundations required for software engineering roles.",

oldPrice:
"₹5499",

newPrice:
"₹4499",

duration:
"2 Months",

status:
"LIVE",

image:
"https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=1200",

modules:[

"Arrays & Strings",
"Linked Lists",
"Trees & Graphs",
"Recursion",
"Dynamic Programming",
"Sliding Window",
"Greedy Algorithms",
"Interview Preparation"

]

},



systemdesign:{

title:
"System Design Program",

description:
"Learn how large-scale systems are designed in modern tech companies. This course covers High Level Design, Low Level Design, databases, caching systems, APIs, load balancing, scalability concepts, and distributed architecture with practical real-world examples.",

oldPrice:
"₹5499",

newPrice:
"₹4499",

duration:
"2 Months",

status:
"LIVE",

image:
"https://images.unsplash.com/photo-1555949963-aa79dcee981c?w=1200",

modules:[

"HLD & LLD",
"Database Design",
"Caching",
"Scalability",
"API Design",
"Microservices",
"Load Balancing",
"Architecture Design"

]

},



ai:{

title:
"Artificial Intelligence Program",

description:
"Explore the world of Artificial Intelligence and Machine Learning with practical implementation. Learn AI models, prompt engineering, neural networks, machine learning basics, AI workflows, and industry tools used in modern AI applications.",

oldPrice:
"₹5499",

newPrice:
"₹4499",

duration:
"2 Months",

status:
"LIVE",

image:
"https://images.unsplash.com/photo-1677442136019-21780ecad995?w=1200",

modules:[

"Machine Learning",
"AI Models",
"Prompt Engineering",
"Neural Networks",
"Data Processing",
"Generative AI",
"Deep Learning",
"AI Projects"

]

},



mastery:{

title:
"DSA + System Design + AI",

description:
"Complete technology mastery program combining DSA, System Design, and Artificial Intelligence into one powerful roadmap. This long-term intensive program prepares students for placements, software engineering interviews, industry-level development, and modern AI workflows.",

oldPrice:
"₹16499",

newPrice:
"₹8499",

duration:
"5-6 Months",

status:
"LIVE",

image:
"https://images.unsplash.com/photo-1515879218367-8466d910aaa4?w=1200",

modules:[

"Advanced DSA",
"System Design",
"Artificial Intelligence",
"Projects",
"Interview Preparation",
"Problem Solving",
"Production Concepts",
"Placement Guidance"

]

},



software:{

title:
"Software / Web Development Internship",

description:
"Gain practical industry experience by working on real-world software and web development projects. Learn frontend development, backend systems, APIs, databases, deployment, Git/GitHub workflow, and modern development practices under mentorship.",

oldPrice:"",
newPrice:"₹6000",

duration:"6 Months",

status:"OPEN",

image:
"https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=1200",

modules:[

"Frontend Development",
"Backend Development",
"REST APIs",
"Database Design",
"Git & GitHub",
"Deployment",
"Industry Workflow",
"Real Projects"

]

},



aiml:{

title:
"AI / ML Internship",

description:
"Work on Artificial Intelligence and Machine Learning projects involving predictive models, data analysis, AI algorithms, neural networks, and industry-level AI applications. Build practical AI experience through project-based learning.",

oldPrice:"",
newPrice:"₹6000",

duration:"6 Months",

status:"OPEN",

image:
"https://images.unsplash.com/photo-1677756119517-756a188d2d94?w=1200",

modules:[

"Machine Learning",
"Predictive Models",
"Data Analysis",
"AI Algorithms",
"Dataset Training",
"Deep Learning",
"Python for AI",
"Industry Projects"

]

}

};




const params =
new URLSearchParams(
window.location.search
);

const course =
params.get("course");

const item =
data[course];



if(!item){

document.body.innerHTML = `

<h1
style="
color:white;
text-align:center;
margin-top:100px;
font-size:50px;
"
>

Course Not Found

</h1>

`;

throw new Error(
"Invalid Course"
);

}



document.getElementById(
"title"
).innerText =
item.title;

document.getElementById(
"description"
).innerText =
item.description;

document.getElementById(
"oldPrice"
).innerText =
item.oldPrice;

document.getElementById(
"newPrice"
).innerText =
item.newPrice;

document.getElementById(
"duration"
).innerText =
item.duration;

document.getElementById(
"status"
).innerText =
item.status;

document.getElementById(
"course-image"
).src =
item.image;



document.getElementById(
"modules"
).innerHTML =

item.modules.map(
m=>`

<div class="module">
${m}
</div>

`
).join("");